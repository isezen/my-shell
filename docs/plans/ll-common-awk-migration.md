# Plan: `ll_common.awk` Migration Completion

**Durum:** Draft — 2026-04-13
**Branch:** `ll-common-awk`
**İlgili dosyalar:** `scripts/bin/ll_common.awk`, `scripts/bin/ll_linux`, `scripts/bin/ll_macos`

## Amaç

`ll_linux` ve `ll_macos` arasında byte-level output paritesini, `scripts/bin/ll_common.awk`
üzerinden paylaşılan tek bir render/format/color katmanıyla sağlamak. Bugün `ll_macos` bu
paylaşıma tamamen geçmiş durumda; `ll_linux` ise opt-in bir flag ardında yarı yolda
kalmış ve flag'in kendisi şu anda **bozuk**. Bu plan, migration'u tamamlamak için
atılması gereken somut adımları tanımlar.

## Mevcut Durum (snapshot)

| Bileşen | Kod yolu | Ölçü | Common kullanımı |
|---|---|---|---|
| `ll_common.awk` | scripts/bin/ll_common.awk | 530 satır / 36 function | — |
| `ll_macos` | scripts/bin/ll_macos | 1113 satır / 0 inline awk function | ✅ `-f "$LL_COMMON_AWK"` koşulsuz (l.251, l.812) |
| `ll_linux` | scripts/bin/ll_linux | 717 satır / 16 inline awk function | ⚠️ Opt-in `LL_USE_COMMON_AWK=1`, default **kapalı** |

**Data ingress farkı (kritik):**

- `ll_linux` (l.97): `ls --color -l --time-style=+"%s"` çıktısını **text olarak** parse ediyor. Satır bazlı, ANSI'li, epoch time field'ı içerir. Parser'ı: `parse_line()`, `_find_epoch_span()`, `_is_epoch()`.
- `ll_macos`: `stat -f` ile kendi US-delimited (`$'\037'`) row'larını üretiyor (`batch_push_rows()`). Hazır field array'leri awk'a beslenir; parse gerekmez.

Yani iki driver **aynı render/format API'sini paylaşıyor olsa da**, data ingress yolları
temelde farklı ve öyle de kalması daha temiz. Common kütüphane data ingress'i
kapsamıyor; render, quote, color, time-bucket, size format, symlink rendering
katmanını soyutluyor.

## Bloklar (sed-surgery'nin neden kırık olduğu)

`scripts/bin/ll_linux` l.680-683:

```bash
AWK_PROG=$(printf '%s\n' "$AWK_PROG_STANDALONE" | sed '/^function quote_if_needed/,/^function color_reltime_by_lbl/d')
AWK_PROG=$(printf '%s\n' "$AWK_PROG" | sed 's/BEGIN {/BEGIN {\n  ll_common_init()/')
AWK_PROG=$(printf '%s\n' "$AWK_PROG" | sed 's/color_reltime_by_lbl/color_reltime/g')
```

Sorun: sed aralığı `/quote_if_needed/..../color_reltime_by_lbl/` yedi fonksiyonu bir
arada siliyor:

1. `quote_if_needed` ← common'da karşılığı var (`llc_quote_if_needed` + wrapper)
2. `strip_leading_resets` ← common'da **YOK**, çağrıları `format_name` içinde duruyor
3. `strip_trailing_resets` ← common'da **YOK**, çağrıları `format_name` içinde duruyor
4. `has_nonreset_sgr` ← common'da **YOK**, `format_name` çağırır
5. `format_name` ← common'da **farklı imzada var** (ll_linux: 2 arg `raw, perms`; common: 5 arg `name, perms, target, target_type, target_perms`)
6. `color_perm` ← common'da var (`llc_color_perm` + wrapper)
7. `size_color_numeric` ← common'da var (`llc_size_color_numeric`)
...
son olarak 8. `color_reltime_by_lbl` sınırda → siliniyor ama `color_reltime` rename'i ile çağrılara erişim var

**Silinen ama çağrı tarafında kalan:** `strip_leading_resets`, `strip_trailing_resets`,
`has_nonreset_sgr`. Bunların çağrıları `format_name` içinde ve `format_name`'in
`ll_linux`'taki imzası ile common'daki imzası eşleşmiyor. Bu yüzden `gawk: syntax error`.

**BSD awk uyumluluğu:** Header `# BSD awk compatible` diyor ama `ll_linux`'ta l.383 ve
l.441 **3-arg `match(str, regex, array)`** kullanıyor — bu gawk-only. `ll_linux` zaten
`gawk` tercih eden bir binary seçim mantığına sahip (l.199-203). `ll_common.awk`'ın
kendisi BSD-safe; `ll_macos` `/usr/bin/awk` (BSD) kullanıyor (l.250). Yani gawk-only
feature'lar sadece ll_linux'a yerleşmiş durumda. Migration sırasında:

- `ll_linux` gawk zorunluluğunu koruyacaksa common'a gawk-only shortcut kabul edilebilir; ya da
- `ll_common.awk`'a kesinlikle gawk-only kod girmemeli (her iki driver'ın parite kullanımı için) ve ll_linux bu fonksiyonları kendisi tutmalı (parse_line gibi ingress-katmanı kodu)

## Migration Stratejisi

İki seçenek:

### Seçenek A — Opt-in flag'i canlandır (tutucu)

Mevcut sed-surgery yaklaşımını düzeltip `LL_USE_COMMON_AWK=1` modunu çalışır hale
getir. Default kapalı kalsın; opt-in ile parite test edilsin.

**Artı:** Küçük diff, mevcut kırık mod tamir edilmiş olur
**Eksi:** Duplication persist eder, sed-surgery yaklaşımı gelecek edit'lerde yine
bozulur, CI'da iki mod koşturmak gerek, migration yine "yarıda" sayılır

### Seçenek B — Flag'i kaldır, `ll_linux`'u tek yola çek (tam)

`ll_macos` gibi `ll_linux` da koşulsuz common kütüphaneyi yüklesin. Inline awk
fonksiyonlarından common'daki karşılıkları silinir, common'da karşılığı olmayanlar
(ingress helper'ları) ya common'a taşınır ya da ll_linux'a ait separate file
(`ll_linux.awk`) olarak kalır.

**Artı:** Duplication biter, sed-surgery ihtiyacı kalkar, CI tek modu test eder,
migration tamamlanmış olur
**Eksi:** Daha büyük diff, imza uyumsuzlukları çözülmek zorunda, daha çok test runı

**Önerilen: Seçenek B.** Sebep: sed-surgery fundamentally fragile (bu oturumda 3 ay
sonra açıp bulduğumuz kırıklık bunu kanıtlıyor); opt-in bir flag "flexibility"
sağlamıyor, sadece bakım borcu biriktiriyor.

## Seçenek B — Faz Bazlı Plan

### Faz 0 — Baseline lock (kırılma önleme)

**Amaç:** Migration öncesi `ll_linux` default output'unu deterministik olarak
snapshot et. Bütün sonraki fazlarda bu snapshot'tan sapma olursa fark açık görünsün.

Görevler:

- [ ] `scripts/dev/ll-compare`'i baseline modunda dondur: `LL_NOW_EPOCH=1577836800 LC_ALL=C TZ=UTC LL_NO_COLOR=1 ll_linux $fixture` çıktılarını `tests/fixtures/ll_linux_baseline/` altına kaydet
- [ ] Aynı fixture seti için `ll_macos` çıktısı üret (macOS'ta; CI'nin macOS job'ı yeterli). `tests/fixtures/ll_macos_baseline/` altına
- [ ] `scripts/dev/ll-compare` kullanılarak iki set arasındaki **mevcut** farkları belgele — bugün parite zaten %100 değil; nerelerde ve neden? Bu bulgu faz 3'ün acceptance baseline'ı olur
- [ ] Makefile'a `baseline-lock` hedefi ekle (opsiyonel)

**Acceptance:** baseline çıktıları commit'lendi; `ll-compare` bunlardan herhangi biri
değiştiğinde fail ediyor.

### Faz 1 — `ll_common.awk` kapsam genişletme

**Amaç:** `ll_linux`'taki inline awk fonksiyonlarından `ll_common.awk`'ta eksik olanları
ya common'a taşı ya da ingress-specific olanları `scripts/bin/ll_linux.awk` adıyla
ayrı dosyaya çıkar.

Mevcut inline fonksiyonlar (`AWK_PROG_STANDALONE` içinde, l.229-676):

| Fonksiyon | Satır | Common'da var mı | Aksiyon |
|---|---|---|---|
| `strip_colors` | ~232 | `llc_strip_colors` ✅ | Common'ı kullan, sil |
| `lpad` | ~240 | `llc_lpad` ✅ | Common'ı kullan, sil |
| `rpad` | ~252 | `llc_rpad` ✅ | Common'ı kullan, sil |
| `quote_if_needed` | ~264 | `llc_quote_if_needed` + wrapper ✅ | Common'ı kullan, sil |
| `strip_leading_resets` | ~? | **YOK** ❌ | Common'a taşı (`llc_strip_leading_resets`) — color rendering'in bir parçası |
| `strip_trailing_resets` | ~? | **YOK** ❌ | Common'a taşı |
| `has_nonreset_sgr` | ~? | **YOK** ❌ | Common'a taşı |
| `format_name` | ~? | **FARKLI İMZA** ⚠️ | Common imzası (5 arg) ile ll_linux'un 2-arg çağrısı arasında adapter yaz. Uzun vadede ll_linux'u common imzasına taşı |
| `color_perm` | ~? | `llc_color_perm` + wrapper ✅ | Common'ı kullan, sil |
| `size_color_numeric` | ~? | `llc_size_color_numeric` ✅ | Common'ı kullan, sil |
| `color_size_human` | ~? | `llc_color_size_human` ✅ | Common'ı kullan, sil |
| `time_calc` | ~? | `llc_time_calc` + wrapper ✅ | Common'ı kullan, sil |
| `color_reltime_by_lbl` | ~? | `llc_color_reltime` (ve `color_reltime` wrapper) imza farklı | İmza uyumla, wrapper kullan |
| `_is_epoch` | ~? | **YOK** ❌ | `ll_linux.awk`'a bırak (ingress-specific) |
| `_find_epoch_span` | ~? | **YOK** ❌ | `ll_linux.awk`'a bırak (ingress-specific, 3-arg `match()` kullanır — gawk-only) |
| `parse_line` | ~? | **YOK** ❌ | `ll_linux.awk`'a bırak (ingress-specific, `ls -l` parser) |

Karar noktası:
- `strip_leading_resets`/`strip_trailing_resets`/`has_nonreset_sgr`/`format_name`
  — bunlar gerçekten common'a ait mi? Evet — hepsi render/color layer. ll_macos da
  benzer işi yapmak zorunda (zaten `format_name(name, perms, target, target_type, target_perms)`
  5-arg imzası ile yapıyor). ll_linux'un 2-arg çağrılarını 5-arg'a genişlet: target/target_type/
  target_perms bilinmeyen durumlarda `""` ile çağrılır, `format_name` defansif davranır.

Görevler:

- [ ] `strip_leading_resets`, `strip_trailing_resets`, `has_nonreset_sgr` → `ll_common.awk`'a taşı (`llc_` prefix)
- [ ] `format_name`'i tek imzada birleştir: ll_macos zaten 5-arg kullanıyor, common'daki bu. ll_linux'un çağrı tarafını 5-arg'a çıkar (boş target parametreleriyle)
- [ ] `color_reltime_by_lbl` ile `llc_color_reltime` arasındaki imza farkını kapat — iki tarafın argüman sırası / return format'ı aynı mı? Farklıysa common'a `lbl` parametresi ekle ya da `color_reltime_by_lbl`'i bir wrapper olarak common'a al
- [ ] ll_linux'a özgü ingress kodunu (`parse_line`, `_is_epoch`, `_find_epoch_span`) `scripts/bin/ll_linux.awk` dosyasına çıkar
- [ ] `ll_common.awk`'ta BSD awk uyumluluğunu koru — yeni taşınan fonksiyonlar 3-arg `match()`, `gensub`, `and/or/xor`, `length(array)` kullanmamalı

**Acceptance:** `ll_common.awk`'ta yeni fonksiyonlar test edilebilir halde; `parse_line`
vb. `ll_linux.awk`'a taşınmış; faz 0 baseline'ı hâlâ geçiyor (bu fazda driver
değiştirilmediği için baseline'ın aynı kalması beklenir).

### Faz 2 — `ll_linux` tek moda çek

**Amaç:** `LL_USE_COMMON_AWK` flag'ini sil, `ll_linux`'u `ll_macos` gibi koşulsuz
common kütüphane kullanıcısına dönüştür.

Görevler:

- [ ] `ll_linux` l.216-222: `AWK_COMMON_ARGS` unconditional — flag check kalksın
- [ ] `ll_linux` l.679-711: İki `if [ "$LL_USE_COMMON_AWK" = "1" ]` bloğu silinsin; tek awk çağrısı kalsın (`-f "$LL_COMMON_AWK" -f "$LL_LINUX_AWK_INGRESS"` ile)
- [ ] `AWK_PROG_STANDALONE` inline string'i — artık gerek yok, sil. Driver sadece `$LL_LINUX_AWK_INGRESS` (veya `$LL_LINUX_AWK` — isimlendirme gelen faz 1 kararına bağlı) yükleyecek
- [ ] Awk binary seçimi korunur (gawk preferred — `parse_line`'ın 3-arg `match()` ihtiyacı için)
- [ ] `-v NO_COLOR` / `-v NOW_EPOCH` / `-v DEC_SEP` / `-v USERNAME` / `-v NUMERIC` parametreleri `ll_macos` ile tutarlı hale getirilsin; common init bunları kullanıyor (`ll_common.awk` l.BEGIN'ine bak)
- [ ] `AWK_PROG = sed ...` surgery tamamen silinsin

**Acceptance:** `LL_USE_COMMON_AWK` grep'i 0 sonuç verir; `ll_linux` default
çalıştırmada hâlâ faz 0 baseline'ıyla parite gösterir; `make test-ll-linux` geçer.

### Faz 3 — Cross-platform parite test'i

**Amaç:** `ll_linux` ve `ll_macos` arasında byte-level parite regresyonunu CI'da
yakalamak. Bu, migration'ın asıl değerinin ölçüsüdür.

Görevler:

- [ ] `scripts/dev/ll-compare` — iki implementasyonu deterministik env'de (`LL_NOW_EPOCH=1577836800 LC_ALL=C TZ=UTC LL_NO_COLOR=1`) karşılaştıran bir CI job'ı yaz
- [ ] Bu job yalnızca macOS runner'da koşabilir (ll_macos macOS-only); Linux runner'da da koşturmak için `LL_IMPL_PATH=.../ll_macos` üzerinden cross-compile düşünülebilir ama pratik değil
- [ ] Baseline diff (faz 0'da belgelenen mevcut farklar) — bu farklardan hangileri kabul edilebilir (`UNSPECIFIED`), hangileri fix lazım? `docs/LL_SPECS.md`'i referans al
- [ ] Kabul edilebilir farklar için `ll-compare` script'ine bir allow-list ekle (veya `docs/LL_SPECS.md`'de işaretle)
- [ ] Makefile'a `test-ll-parity` hedefi
- [ ] `.github/workflows/ci.yml`'a parity step

**Acceptance:** CI yeşil yanıyor; `ll-compare ll_linux ll_macos` tüm fixture'lar için
parity PASS veriyor (veya allow-list'te açıkça işaretli); yeni bir regresyon CI'yi
kırıyor.

### Faz 4 — Temizlik & documentation

- [ ] `CHANGELOG.md` — `[Unreleased]` altında migration'un tamamlandığını belirt
- [ ] `docs/LL_SPECS.md` — yeni parity guarantee'ı not et
- [ ] `README.md` "Behavior Contract" bölümünü güncelle — artık ll_linux ve ll_macos tek bir render/format layer'ı paylaşıyor
- [ ] `scripts/bin/ll_common.awk` header comment'ını güncelle — artık her iki driver tarafından da zorunlu
- [ ] Bu plan dosyasını `docs/plan-ll-common-awk-migration.md` `Status: COMPLETED` olarak işaretle ya da arşivle (`docs/archive/` varsa)

## Acceptance Criteria (genel)

Migration başarı ölçütleri:

1. **`grep LL_USE_COMMON_AWK scripts/ tests/ Makefile .github/`** — 0 sonuç
2. **`grep -c '^function' scripts/bin/ll_linux`** — 0 (inline awk kaldırıldı) ya da sadece shell fonksiyonları (karıştırma olmaması için `grep '^\s*function.*{' AWK_PROG' gibi spesifik kontrol)
3. **`make test-ll-all`** — hem Linux hem macOS job'larında PASS
4. **`scripts/dev/ll-compare ll_linux ll_macos`** deterministik env'de — allow-list dışında 0 diff
5. **`LL_NOW_EPOCH=1577836800 LC_ALL=C TZ=UTC LL_NO_COLOR=1 ll_linux $fixture`** çıktısı migration öncesi snapshot'la aynı (render/color regresyonu yok)
6. `ll_common.awk` BSD awk safe — gawk-only pattern taramasında 0 sonuç
7. `CHANGELOG.md`, `LL_SPECS.md`, `README.md` güncel

## Riskler ve Açık Sorular

### Yüksek risk

- **`format_name` imza birleştirme.** ll_linux'un 2-arg parser'ı target bilgisini çağrı
  tarafında (parse_line'dan) ayrıştırıyor; ll_macos 5-arg'ı batch stat'tan doğrudan
  alıyor. 5-arg'a birleştirirken ll_linux target string'ini tekrar nasıl çıkaracak?
  Muhtemelen parse_line target'ı zaten ayırıyor (symlink için `name -> target` pattern'i).
  Bu faz 1'de doğrulanmalı.
- **BSD awk uyumluluğu sınırı.** `ll_common.awk` BSD-safe; ama ll_linux `parse_line`
  3-arg `match()` kullanıyor ve bu gawk-only. Eğer gelecek bir maintainer bu kodu
  common'a taşımaya çalışırsa common BSD-unsafe olur ve ll_macos'u patlatır. `ll_linux.awk`
  ayrı dosyasında gawk-only kabul edilir; common'a dokunma garantisi bir README notu
  veya shellcheck-benzeri bir guard ile sağlanmalı (örn. `scripts/dev/check-common-awk-bsd-safe`)

### Orta risk

- **Turkish locale ll_macos'ta özel case (l.216-224).** `DEC_SEP` ve total label için
  locale-aware branching var. `ll_linux` bunu yapmıyor (ls çıktısı zaten locale'i
  kabul ediyor). Parity test'lerini `LC_ALL=C` ile koştursak da production
  kullanıcılarda farklı davranış sürer. Common init'e `DEC_SEP` parametresi
  geçmek bu işi çözer — zaten geçiyor gibi görünüyor ama doğrulanmalı.
- **Awk binary seçim farkı.** `ll_macos` hardcoded `/usr/bin/awk` (BSD) kullanıyor;
  `ll_linux` gawk tercihli seçiyor. Bir Linux sisteminde macOS'un ll_common.awk'ına
  gawk ile yüklenirse davranış değişir mi? (String indexing, regex flavor, vb.)
  Büyük ihtimalle hayır — common BSD-safe — ama parity CI job'ı bunu dolaylı olarak
  kontrol eder.

### Düşük risk

- **`llc_` prefix naming convention tutarlılığı.** Bazı fonksiyonlarda wrapper
  (`color_perm → llc_color_perm`) var, bazılarında yok. Migration sonrası tüm public
  fonksiyonlar `llc_` prefix'li olmalı; wrapper'lar backward compat için deprecated
  olarak işaretli kalabilir, faz 4'te silinmeleri düşünülebilir (ama breaking change).

## Efor Tahmini

| Faz | İşin boyutu | Tahmin |
|---|---|---|
| Faz 0 | Fixture + baseline snapshot | 1-2 saat |
| Faz 1 | Fonksiyon taşıma + imza birleştirme + ll_linux.awk ayrıştırma | 3-5 saat |
| Faz 2 | Flag ve sed-surgery temizliği | 1-2 saat |
| Faz 3 | Parity CI job + allow-list + fixture genişletme | 2-3 saat |
| Faz 4 | Docs ve CHANGELOG | 30 dk |
| **Toplam** | | **~1 gün** |

Risk katsayısı ile: ~1.5 gün.

## İşlemeli Sıra

Bu plan dosyası işin özetini verir; icra sırasında her faz için ayrı bir ticket/PR
açılır. Fazları sırayla yürüt — faz atlamak baseline locku zayıflatır ve regresyon
gürültüsünü kaynağıyla ayırt etmek zorlaşır.

Önerilen PR akışı:

1. **PR #1** — Faz 0: baseline fixture'ları (review: küçük, risk yok)
2. **PR #2** — Faz 1: common'a fonksiyon taşıma + `ll_linux.awk` dosyası (review: orta)
3. **PR #3** — Faz 2: flag'i kaldır, tek moda çek (review: orta)
4. **PR #4** — Faz 3: parity CI + docs (review: küçük)

Her PR ayrı bir commit serisi ama aynı `ll-common-awk` dalı üzerinde ardı ardına
ilerleyebilir. Master'a merge tek seferde veya PR başına yapılabilir.

## Phase 0 Findings (2026-04-13)

Faz 0 sırasında açığa çıkan somut durum.

### Bulgu 1 — Pre-existing blocker: `ll_common_init()` division by zero

`scripts/bin/ll_common.awk:291` — `ll_common_init()` `NO_COLOR==1` olduğunda
`llc_init_time_constants()` ve `llc_init_size_constants()`'i çağırmadan erken
return yapıyordu. Bu yüzden `NO_COLOR=1` modunda `llc_TIME_MIN=0` kalıyor,
`llc_time_calc()` çağrısında `int(dt / llc_TIME_MIN)` division by zero patlamasına
yol açıyordu. `ll_macos` tüm zaman hesaplamalarında patlıyor; `make test-ll-macos`
3 testten sonra fail ediyordu (commit `7d3cb41`'den beri, ~3 ay). `make test-bats`
bu suite'i kapsamadığı için fark edilmemiş.

**Fix:** `llc_init_size_constants()` ve `llc_init_time_constants()` çağrıları
NO_COLOR erken return'ünden **önceye** taşındı. Artık NO_COLOR modunda da sabitler
doğru set ediliyor.

### Bulgu 2 — Test/harness çelişkisi: ll_macos color tests

`tests/ll_macos/10_core.bats` içindeki 3 test (`time buckets and colors`,
`perms and owner colors`, `size tier colors`) ANSI color code'ları assert
ediyor. Ama `tests/ll_macos/00_harness.bash:9` global olarak `LL_NO_COLOR=1`
set ediyor. Commit `7d3cb41` eski `LL_CHATGPT_FAST=1` ortak bayrağını `LL_NO_COLOR=1`
ile değiştirirken testlerde `unset LL_CHATGPT_FAST` satırlarını sildi ama karşılığında
`LL_NO_COLOR=0` override'ı eklemedi.

**Fix:** 3 color test'ine `LL_NO_COLOR=0 run "${LL_MACOS_IMPL}" ...` inline
override eklendi. 7/7 test geçiyor.

### Bulgu 3 — `ll_linux` default mode NO_COLOR'ı onurlandırmıyor

`scripts/bin/ll_linux` `AWK_PROG_STANDALONE` inline awk program'ı `NO_COLOR`
variable'ını **hiç okumuyor**. `LL_NO_COLOR=1` env ayarı shell tarafında alınıp
`-v NO_COLOR="$NO_COLOR"` ile awk'a gönderiliyor ama awk içinde referans yok.
Sadece opt-in `LL_USE_COMMON_AWK=1` path'i `ll_common_init()` üzerinden NO_COLOR'ı
onurlandırıyor (o da ayrıca bozuk).

**Sonuç (Phase 0 scope içinde fix edilmedi, Phase 2'nin temizlik kapsamında):**
ll_linux default mode'da emitlenen ANSI bytes baseline snapshot'lara girdi.
Semantik içerik NO_COLOR ile aynı; sadece görsel katmanda fark var. Phase 2
ll_linux'u common.awk'a bağladığında bu fark kendiliğinden kapanacak.

### Bulgu 4 — Cross-platform parity **zaten %100 semantik olarak var**

Phase 0'ın temel değer bulgusu: `scripts/dev/ll-compare --fail-only ll_linux ll_macos`
byte-level olarak **50/52 fail** verir — ama bu fail'ların **tamamı sadece ANSI
farkından** kaynaklanır. ANSI strip sonrası karşılaştırmada:

```
ANSI-stripped: 52 identical, 0 differ
```

Yani mevcut `ll_macos` ve `ll_linux` implementasyonları arasındaki gerçek
semantik (field layout, time bucket, filename render, symlink arrow, width,
quoting, ordering) parite **şu an zaten tam**. `ll_common.awk` + platform-specific
data ingress mimarisi çalışıyor.

**Phase 2+ değeri:** ll_linux'un ANSI'yi common.awk üzerinden yönetmesi byte-level
parity'yi de otomatik sağlar. Phase 3 parity CI job'ı basit bir byte-equality
check olabilir (ANSI strip bile gerekmez — çünkü iki driver da aynı common
init'ten geçecek).

**Phase 0'da geçici durum:** Snapshot'lar driver başına ayrı tutuluyor
(`tests/fixtures/ll_baseline/ll_linux/` vs `tests/fixtures/ll_baseline/ll_macos/`).
Her driver kendi current-state'ini locklar. Phase 2 sonrası iki klasör
birleştirilebilir (veya sadece `ll_baseline/` altında tek set tutulabilir, çünkü
byte-identical olacaklar).

### Bulgu 5 — ll_linux test suite on macOS host (out of scope)

`tests/ll_linux/40_color.bats` tests use `run "${LL_SCRIPT}"` (ll wrapper)
directly. On macOS host, the wrapper dispatches to `ll_macos` (`uname=Darwin`).
So these "ll_linux color tests" actually exercise ll_macos on macOS — and with
the harness's `LL_NO_COLOR=1` they now return uncolored output while the tests
assert color codes.

**Not fixed in Phase 0.** This is a pre-existing test-infrastructure bug
unrelated to the ll_common.awk migration. It should be tracked separately:
either (a) force `LL_IMPL=linux` in the color tests that are intended to
exercise ll_linux, or (b) soft-skip those tests on Darwin hosts. The Linux
CI runner is unaffected (wrapper dispatches to ll_linux correctly on Linux).

### Phase 0 deliverables

- `scripts/dev/ll-compare --snapshot <DIR>` opsiyonu eklendi — raw output'ları
  `<DIR>/<script_name>/NNN_<slug>.out` olarak yazar, PASS/FAIL karşılaştırma
  yapmaz, tek script invocation'a izin verir
- `tests/fixtures/ll_baseline/ll_linux/` (52 dosya) — `ll_linux` default-mode
  output'u, ANSI dahil
- `tests/fixtures/ll_baseline/ll_macos/` (52 dosya) — `ll_macos` NO_COLOR mode
  output'u, ANSI yok (düzeltilmiş common.awk NO_COLOR path'ine bağlı)
- `tests/ll/20_baseline_snapshot.bats` — her case'i çalıştırıp snapshot'la
  byte-equal assert eden regresyon kilidi (Task 7)
- `Makefile` — `baseline-regen` ve `baseline-check` hedefleri (Task 8)
- `docs/plans/ll-common-awk-migration.md` — bu bulgular bölümü

### Phase 0'ın değeri

1. **ll_common.awk latent bug'ı açığa çıkarıldı ve fix edildi** — tek başına
   3 aylık bir regression'ı tamir ediyor
2. **ll_macos test suite tekrar yeşil** — 7/7 geçiyor
3. **Semantic parity zaten var olduğu doğrulandı** — Phase 2'nin işi "tek
   satır flag kaldır ve inline kodu sil" boyutunda, tasarım değişikliği değil
4. **Byte-level regression kilidi kuruldu** — Phase 1-4 sırasında yapılan
   her değişiklik bu snapshot'lara göre ölçülecek, sürpriz davranış değişikliği
   olursa CI/local testte görünür

---

## Referanslar

- Branch divergence: `git log master..ll-common-awk --oneline` (131 commit)
- İlk `ll_common.awk` commit: `9a31f16` (10 Oca 2026)
- ll_macos → common migration: `acce62d` (10 Oca 2026)
- ll_linux opt-in eklendi: `9af0bc2` (10 Oca 2026)
- Function rename (llc_ prefix): `101e9b5` (11 Oca 2026)
- O tarihten sonra `ll_linux`/`ll_common.awk` üçlüsüne teknik commit YOK
- `docs/LL_SPECS.md` — ll ailesi davranış sözleşmesi
- `docs/proj_summary.md` — projeye dair ayrıntılı özet
