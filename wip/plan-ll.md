
## Phase 1–2 — Exact commit sıralaması ve mesajları (Cursor için yürütme planı)

Aşağıdaki commit sırası **zorunludur**. Her commit’ten **hemen önce** `CHANGELOG.md` dosyasına ilgili değişikliklerin kısa bir özeti eklenmelidir.

### CHANGELOG kuralı (her commit için)
- Commit atmadan önce mutlaka `CHANGELOG.md` güncellenecek.
- Kayıt formatı serbest; ancak her giriş en az şu bilgileri içermeli:
  - Kısa başlık (ne değişti?)
  - Etkilenen alan(lar): wrapper / tests / ci / makefile
  - Eğer davranış değişikliği yoksa açıkça: “No behavior change; refactor/test only.”

### Known traps (must-fix)
- **CI report steps must not run stale globs.** Workflow “report/summary” steps currently run `bats tests/*.bats tests/ll/*.bats`. After Phase 1, the GNU suite moves to `tests/ll_linux/`, so report steps MUST be updated to call `make test-ll` (preferred) or the correct per-OS globs.
- **macOS implementation must not use tab-delimited rows.** Fixtures include a filename containing a literal tab (`a\tb.txt`). Any internal “rows” format in `ll_macos` MUST NOT use `\t` as a delimiter. Use ASCII Unit Separator (0x1F) or an equivalent safe delimiter.
- **tests/ll is common-only.** `tests/ll/*.bats` MUST remain toolchain-independent (no GNU ls/gawk, no BSD stat baseline). Semantic equality tests live only in `tests/ll_linux` and `tests/ll_macos`.
- **CI report/summary MUST NOT re-run bats with hardcoded globs.** The workflow summary steps currently run `bats tests/*.bats tests/ll/*.bats` (and similar). After Phase 1–2, this will be stale and/or incomplete. Summary/report steps MUST be updated to capture the output of `make test-ll` (preferred) and MUST NOT run `bats ...` directly. If re-running is unavoidable, it must use the per-OS suite globs (Ubuntu: include `tests/ll_linux/*.bats`, macOS: include `tests/ll_macos/*.bats`).
- **Newline in filenames is explicitly out of scope.** Internal row/record formats are line-based. Filenames (and symlink targets) containing literal `\n` are not supported and are not part of this repo’s fixture/test scope. Do not attempt to “support newline filenames” within Phase 1–3; treat it as a separate future phase if ever needed.

### Commit 1 — Test suite dizinlerini oluştur ve GNU suite’i taşı
**Amaç:** `tests/ll` içindeki GNU-baseline suite’i `tests/ll_linux/` altına almak; `tests/ll`’yi boşaltmadan (henüz) sadece yeniden konumlandırmak.

**Değişiklikler:**
- Yeni klasörleri oluştur:
  - `tests/ll_linux/`
  - `tests/ll_macos/`
- Mevcut dosyaları taşı:
  - `tests/ll/00_harness.bash` -> `tests/ll_linux/00_harness.bash`
  - `tests/ll/10_core.bats`    -> `tests/ll_linux/10_core.bats`
- Taşıma sonrası **path** güncellemelerini yap (relative `load` yolları, `PROJECT_ROOT` hesapları vb.).
- `tests/ll_macos/` için **yalnızca dizin + minimal preflight** ekle (bu commit’te semantic test yok):
  - `tests/ll_macos/00_harness.bash` (yalnızca `ll_warn`, `ll_soft_skip`, `ll_require_macos_userland`)
  - `tests/ll_macos/10_core.bats` (tek test: Darwin değilse soft-skip; Darwin ise PASS)

**Test (yerel):**
- Linux: `bats tests/ll_linux/*.bats`
- macOS (GNU varsa): `bats tests/ll_linux/*.bats`

**Commit mesajı:**
- `test(ll): split test suites; move GNU baseline tests to tests/ll_linux`

---

### Commit 2 — Wrapper/common suite için stub tabanlı test iskeletini ekle
**Amaç:** `tests/ll/` altında platform bağımsız wrapper sözleşmesi testlerini koşturmak.

**Değişiklikler:**
- Yeni dosyaları ekle:
  - `tests/ll/fixtures/ll_stub_impl.bash`
  - `tests/ll/10_wrapper_stub.bats`
- Bu suite’in **GNU ls/gawk/stat** bağımlılığı olmayacak.
- Testler wrapper’ın şu sözleşmelerini doğrular:
  - `LL_IMPL_PATH` önceliği
  - `LL_IMPL=linux|macos` seçimi
  - `LL_SCRIPT` recursion guard
  - Arg forwarding (özellikle `--`, space/tab/unicode arg’lar)
  - Invalid `LL_IMPL` için exit=2

**Test (yerel):**
- `bats tests/ll/10_wrapper_stub.bats`

**Commit mesajı:**
- `test(ll): add stub-based wrapper tests in tests/ll`

---

### Commit 3 — Makefile test hedeflerini ekle
**Amaç:** CI ve local için deterministik, platform-aware test hedefleri sağlamak.

**Değişiklikler (Makefile):**
- Aşağıdaki hedefleri ekle/güncelle:
  - `test-ll-common`  -> `bats tests/ll/*.bats`
  - `test-ll-linux`   -> `bats tests/ll_linux/*.bats`
  - `test-ll-macos`   -> `bats tests/ll_macos/*.bats`
  - `test-ll`         -> OS’e göre (Linux: common+linux; macOS: common+macos)
  - `test-ll-all`     -> common + linux + macos (uygun olmayanlar soft-skip ile 0 dönmeli)
- Mevcut `test-bats` hedefi şimdilik korunabilir; ancak Phase 2’de CI ondan ayrılacak.

**Test (yerel):**
- Linux: `make test-ll-common && make test-ll-linux`
- macOS: `make test-ll-common && make test-ll-macos`

**Commit mesajı:**
- `chore(make): add test-ll targets (common/linux/macos/all)`

---

### Commit 4 — CI workflow’larında make test-ll hedeflerini çağır
**Amaç:** GitHub Actions’ta her OS’in kendi suite’ini zorunlu koşturmak.

**Değişiklikler (.github/workflows/ci.yml):**
- Ubuntu job:
  - `make test-bats` yerine: `make test-ll`
- macOS job:
  - `make test-bats` yerine: `make test-ll`
- **ZORUNLU:** Raporlama/summary adımlarında kullanılan test komutları da güncellenecek.
  - Tercih: rapor adımlarında **yeniden** `bats ...` çalıştırma. Bunun yerine `make test-ll` çağır ve stdout’u yakala.
  - Eğer yeniden `bats` çalıştırılacaksa:
    - Ubuntu: `bats tests/*.bats tests/ll/*.bats tests/ll_linux/*.bats`
    - macOS:  `bats tests/*.bats tests/ll/*.bats tests/ll_macos/*.bats`
- **Hard rule:** CI summary/report steps MUST NOT run `bats ...` directly (no hardcoded globs). They must run `make test-ll` and capture stdout/stderr for the report. This prevents stale/incomplete globs after the suite split.

**Test (yerel, hızlı doğrulama):**
- Linux: `make test-ll` (CI simülasyonu)

**Commit mesajı:**
- `chore(ci): run test-ll per OS instead of test-bats`

---

### Commit 5 — scripts/bin/ll wrapper’ı “thin dispatch” sözleşmesine sabitle
**Amaç:** Wrapper sözleşmesini (öncelik sırası, exit code) testlerle birlikte kalıcı hale getirmek.

**Değişiklikler:**
- `scripts/bin/ll`:
  - Öncelik sırası: `LL_IMPL_PATH` > `LL_SCRIPT` (recursion guard) > `LL_IMPL` > OS sniff
  - Exit code: 1 (missing/unexecutable), 2 (invalid LL_IMPL)
  - Arg forwarding: değiştirmeden ilet

**Test (yerel):**
- `make test-ll-common`

**Commit mesajı:**
- `feat(ll): harden thin wrapper dispatch contract`

---

### Commit 6 — Phase 2 başlangıcı: ll_macos için BSD-only hedefini netleştir (yalnızca sözleşme + preflight)
**Amaç:** GNU tools olmadan macOS’ta koşabilecek bir ll_macos geliştirmesinin çerçevesini sabitlemek. Not: Commit 1 yalnızca minimal placeholder koyar. Commit 6, preflight helper’larını finalize eder ve Darwin üzerinde PASS eden tek smoke testi garanti eder.

**Değişiklikler:**
- `tests/ll_macos/00_harness.bash`:
  - `ll_require_macos_userland` ve `ll_warn/ll_soft_skip` yardımcılarını kesinleştir.
- `tests/ll_macos/10_core.bats`:
  - En az 1 adet “preflight passes on Darwin” testi.
  - Darwin değilse soft-skip.
- Bu commit davranış değiştirmemeli; amaç sadece Phase 3 implementasyonuna zemin hazırlamak.

**Test (yerel):**
- macOS: `make test-ll-macos`
- Linux: `make test-ll-macos` (soft-skip ile 0 dönmeli)

**Commit mesajı:**
- `test(ll_macos): add BSD-only preflight skeleton for macOS suite`

---

### Phase 1–2 çıkış kriteri (bu bölüm tamamlanmadan Phase 3’e geçme)
- `make test-ll-common` hem Linux hem macOS’ta yeşil.
- Linux’ta: `make test-ll` = common + ll_linux suite yeşil.
- macOS’ta: `make test-ll` = common + ll_macos skeleton yeşil.
- Yanlış platformda:
  - Linux’ta `make test-ll-macos` soft-skip ile 0 döner.
  - macOS’ta GNU yoksa `make test-ll-linux` soft-skip ile 0 döner.
- CI workflow report/summary adımları doğru suite’leri çalıştırır (stale glob yok); tercihen rapor adımı `make test-ll` kullanır.

## Mevcut Durum (Repo Gerçekleri ile Kilitlenmiş)

- GNU baseline suite taşındı: `tests/ll_linux/00_harness.bash` ve `tests/ll_linux/*.bats` artık **GNU ls/gawk** varsayımıyla çalışıyor.
- `tests/ll/` dizini **yalnızca wrapper/common** testleri içeriyor (toolchain bağımsız).
- `tests/ll_macos/` içinde **BSD reference generator + parity testleri** mevcut; GNU ls baseline kullanılmıyor.
- CI pipeline’ında hem Linux hem macOS job’ları **`make test-ll`** çağırıyor; report adımları `.ci-test-ll.log` üzerinden çıktı üretip **bats globs çalıştırmıyor**.
- Makefile’da `test-ll-common/linux/macos/ll/all` hedefleri mevcut ve platform ayrımı yapılmış durumda.

## ll_linux + ll_macos + unified ll — ayrıntılı uygulama planı (adım adım)

## Bu doküman nasıl kullanılacak (Cursor planlayıcısı için)

Bu doküman, Cursor planlayıcısında doğrudan yürütülebilecek bir kontrol listesi ve adım adım uygulama rehberidir. Her adımda hangi dosyaların değişeceği, hangi komutların çalıştırılacağı ve başarı kriterlerinin ne olduğu açıkça belirtilmiştir.

- Her adım: (a) değiştirilecek dosyalar, (b) komutlar, (c) başarı kriteri net şekilde belirtilir.
- Fail yerine skip+warning politikası yalnızca platform-suite preflight’lerinde geçerlidir.
- Wrapper testleri stub tabanlıdır ve platformdan bağımsızdır.

Bu plan, iki ayrı implementasyonla (`ll_linux`, `ll_macos`) başlayıp; test, determinism ve performans ölçümleriyle karar vererek gerekirse tek bir `ll` altında birleşmeyi hedefler.

Öncelik sırası:
1) Correctness (semantik)  2) Determinism  3) Portability  4) Performance

Bu doküman **varsayım yapmaz**: burada geçen her adım, repo içindeki gerçek davranış/test çıktıları ile doğrulanacak şekilde tasarlanmıştır.

---

## Tanımlar

- **Canonicalization sonrası eşdeğerlik:** Çıktıların byte-level aynı olması değil; canonicalizer’ların normalize ettiği kurallara göre semantik olarak aynı olması.
- **BSD-only mode (macOS):** PATH’ten `gnubin` önceliklerini kaldırıp `/bin/ls`, `/usr/bin/awk`, `/usr/bin/stat` ile test koşmak.
- **Reference generator:** Testlerde “baseline” olarak kullanılan, OS’e uygun güvenilir referans çıktı üreticisi.

- **Yerel test kapsama uyarıları:** Geliştirme OS’ine göre bazı implementasyonların yerelde test edilememesi normaldir; bu durum *açıkça uyarı* üretmeli ve testler yalnızca CI’da doğrulanmalıdır.

- **Preflight (soft):** Gerekli araçların veya ortamın mevcut olup olmadığını kontrol eden, eksikse testleri `skip` edip bir WARNING satırı basan (suite’i fail etmeyen) fonksiyon veya adım.
- **Native suite:** Her OS üzerinde yalnızca o OS’ye özgü semantik test suite’inin CI’da koşmasının zorunlu olması; diğer suite’ler yalnızca uygun ortamda (örn. GNU tools yüklü macOS) opsiyonel olarak koşar.

---

## Phase 0 — Çalışma zemini ve “mevcut davranış” snapshot

### 0.1 Branch ve kapsam
1) Yeni branch aç:
   - Örn: `improve-ll-portability`
2) Bu branch’te hedef:
   - `scripts/bin/ll` = thin wrapper (dispatch)
   - `scripts/bin/ll_linux` = GNU odaklı implementasyon
   - `scripts/bin/ll_macos` = BSD userland implementasyon
   - Testler hem Linux hem macOS’ta anlamlı doğrulama yapacak

   - Çıktı hedefleri (dosya bazlı):
     - `scripts/bin/ll` (wrapper)
     - `scripts/bin/ll_linux`
     - `scripts/bin/ll_macos`
     - `tests/ll/` (wrapper/common suite)
     - `tests/ll_linux/` (GNU semantics suite)
     - `tests/ll_macos/` (BSD semantics suite)
     - `Makefile` hedefleri: `test-ll-common`, `test-ll-linux`, `test-ll-macos`, `test-ll`, `test-ll-all`

### 0.2 Determinism korunumu
3) Test determinism’ini sabitleyen env’lerin dokümantasyonu:
   - `LL_NOW_EPOCH` freeze
   - `LC_ALL=C`, `TZ=UTC`
   - Test fixture mtimeleri frozen

### 0.3 “Before” snapshot
4) Linux tarafı (GNU toolchain):
   - `bats tests/ll/*.bats`
   - varsa `scripts/dev/ls-compare` ile ek doğrulama
5) macOS tarafı (iki modda):
   - **GNU tools var mod** (senin sistem gibi): normal PATH ile
   - **BSD-only mode**: gnubin’leri PATH’ten çıkararak
6) Çıktılar:
   - “Before” logs (test pass/fail, diff örnekleri)

### 0.4 Yerel test edilebilirlik matrisi ve uyarılar

1) **Linux üzerinde geliştirme**
   - Gerçek BSD userland olmadığı için `ll_macos` yerelde güvenilir biçimde test edilemez.
   - Beklenen davranış:
     - Yerel koşumda `ll_macos`’a ait test hedefi *uyarı* verir ve *skip* eder.
     - `ll_macos` doğrulaması yalnızca **CI macOS job** üzerinde yapılır.
     - Önerilen WARNING metni: `WARNING: ll_macos tests cannot run on Linux locally; they are validated in macOS CI. Skipping.`

2) **macOS üzerinde geliştirme**
   - `ll_macos` her zaman **doğrudan** Apple userland binary’lerini kullanır:
     - `/bin/ls`, `/usr/bin/awk`, `/usr/bin/stat` (gerekirse `readlink`/`perl` mevcut olanlar)
   - `ll_linux` yalnızca GNU toolchain ile test edilebilir.
     - Eğer GNU coreutils (özellikle GNU `ls` ve tercihen `gawk`) kurulu değilse:
       - Beklenen davranış: `ll_linux` test hedefi *uyarı* verir ve *skip* eder.
       - Uyarı metni yönlendirmesi: “GNU coreutils kur (MacPorts/Homebrew), sonra ll_linux’u yerelde test edebilirsin; aksi halde ll_linux sadece Linux CI’da doğrulanır.”
     - Önerilen WARNING metni: `WARNING: ll_linux tests require GNU coreutils (gls) and preferably gawk. Install via MacPorts/Homebrew to run locally; validated in Linux CI. Skipping.`

3) **Amaç ve gerekçe**
   - Bu yaklaşım:
     - Yanlış-pozitif “portability” hissini engeller (Linux’ta BSD stat taklidi yok).
     - macOS’ta `ll_macos`’un gerçekten BSD araçlarıyla çalıştığını garanti eder.
     - `ll_linux`’un GNU bağımlılıklarını açık ve yönetilebilir kılar.

### 0.5 Commit Disiplini (Zorunlu)

- Her phase veya alt-phase sonunda **tek odaklı** commit atılacaktır.
- Commit mesajı formatı aşağıdaki gibi olmalıdır:
  - `feat(ll): ...`
  - `test(ll): ...`
  - `refactor(ll): ...`
  - `chore(ci): ...`
- Cursor, **her adımı tamamladıktan sonra** ilgili commit’i atmalıdır; birden fazla değişiklik *tek commit’e* bölünmemelidir.

---

## Phase 1 — Binary split ve wrapper netliği

### 1.1 Mevcut GNU odaklı implementasyonu isimlendirme
1) Mevcut GNU odaklı implementasyonun adı **net** olmalı:
   - `scripts/bin/ll_linux` (GNU `ls --time-style=+%s` ve gawk ile hızlı yol)
2) `scripts/bin/ll` artık bu kodu içermeyecek.

### 1.2 Thin wrapper: `scripts/bin/ll`
3) `scripts/bin/ll` sadece şu işi yapacak:
   - OS sniff (`uname`)
   - macOS ise `ll_macos`
   - diğerlerinde `ll_linux`
   - override için env desteği (test/deney için):
     - örn: `LL_IMPL=linux|macos` veya `LL_FORCE_IMPL=...` (adı repo’da netleştirilecek)
4) Wrapper içinde **business logic olmayacak**.

### 1.3 Test harness’in hangi binary’yi çağıracağı
5) Test suite default olarak:
   - `LL_SCRIPT` değişkeni üzerinden **wrapper `ll`’yi** çalıştırır.
   - Böylece gerçek kullanıcı deneyimi test edilmiş olur.
6) Ek olarak (opsiyonel ama faydalı):
   - `LL_SCRIPT` override ile doğrudan `ll_linux`/`ll_macos` testleri de koşulabilir.

Deliverable:
- Linux’ta `tests/ll/*` wrapper üzerinden geçer.
- macOS’ta wrapper mevcut OS’e göre doğru implementasyonu seçer.

### 1.4 Wrapper sözleşmesi (exit code ve öncelik sırası)

- Öncelik sırası:
  1) `LL_IMPL_PATH` (varsa, mutlak veya relatif path ile doğrudan exec edilir)
  2) `LL_SCRIPT` (set ise ve wrapper kendisine işaret etmiyorsa; recursion guard ile)
  3) `LL_IMPL` (`linux` veya `macos`; yoksa OS sniff)
  4) OS default (Darwin ise `ll_macos`, değilse `ll_linux`)
- Exit code:
  - 1: İstenen executable yok veya çalıştırılamıyor
  - 2: `LL_IMPL` değeri geçersiz (ne `linux` ne `macos`)
- Wrapper hiçbir zaman argümanları yeniden yazmaz veya değiştirip iletmez; sadece olduğu gibi forward eder.

---

## Phase 2 — macOS’ta “GNU tools varsa da yoksa da” hedefi

Bu projenin ana şartı:
- GNU ls/gawk yoksa **skip** değil; BSD userland ile de test ve doğrulama yapılacak.

Bunun için iki şey gereklidir:
1) `ll_macos` implementasyonu (BSD stat/ls/awk)
2) Test harness’te macOS için GNU ls yerine **BSD reference generator**

---

## Phase 3 — ll_macos MVP (BSD stat/ls/awk) — Minimal Plan

### 3.1 Kapsam ve başarı kriteri

#### MUST (v1)
- Tek satır formatı (canonicalizer’ların beklediği alanlar):
  - perms, link count, owner, group, size(bytes veya human), relative time, filename
- Relative time bucket’ları:
  - `sec/min/hrs/day/mon/yr` + future (`in ...`)
- Renk semantiği (en az):
  - time buckets + future
  - perms segment (d/l/- ve rwx karakterleri)
  - owner segment (`you` vs `root`)
  - size tier (B/KB/MB/GB/TB)
- Zor filename’ler:
  - space, tab, unicode
  - symlink `name -> target`
- `--` sentinel:
  - option parse’ı kırmadan operand’ları taşıyabilmeli

#### MAY (v2)
- ACL/EA marker (`+`, `@`) renklendirme
- setuid/setgid/sticky ek semantik/renk
- `-h/--si` human size
- `-s/--size` blocks column

Başarı ölçütü:
- `tests/ll/*`: **canonicalization sonrası** eşdeğerlik

---

### 3.2 Mimari: Collector + Formatter (tek script içinde, iki aşama)

`ll_macos` içinde iki aşama:

1) **Collector**
   - BSD `stat` tabanlı güvenilir alanları toplar
   - Makine-okur bir ara format üretir

2) **Formatter**
   - `/usr/bin/awk` ile:
     - relative time
     - renk
     - hizalama
     - final tek satır output

Not:
- `ls -l` parse etmek yerine `stat` tabanlı ilerlemek deterministikliği artırır.

---

### 3.3 Collector tasarımı (BSD `stat`)

#### 3.3.1 Toplanacak alanlar (v1)
Her entry için:
- type (en az: file/dir/link; diğerleri best-effort)
- perms string (örn: `-rwxr-xr-x`)
- nlink
- owner (name)
- group (name)
- size_bytes
- mtime_epoch
- name (raw)
- link_target (symlink ise, raw)

#### 3.3.2 `stat -f` formatı
macOS `stat -f` placeholder’lar:
- `%N` : name (path as provided; bazı durumlarda `name -> target` gösterebilir)
- `%z` : size
- `%m` : mtime epoch
- `%Su` : owner name
- `%Sg` : group name
- `%l` : link count
- `%p` : mode bits (octal/numeric)

Perks/perms üretimi:
- Eğer `%Sp` (permission string) mevcutsa doğrudan kullan
- Yoksa `%p` ile mode bits alıp awk içinde `rwx` string’e dönüştür

Symlink target:
- `readlink "$path"` ile target alın (best-effort)

### 3.3.3 Ara format (delimiter) — MUST
TSV/tab delimiter **kullanmak yasaktır** çünkü test fixture’larında tab içeren dosya adı vardır (`a\tb.txt`).

- Ara format delimiter’ı **ASCII Unit Separator (0x1F)** olacak:
  - `DELIM=$'\037'`
- Collector satırı alanları (NAME/TARGET dahil) delimiter ile ayrılacak:
  - `TYPE<US>PERMS<US>NLINK<US>OWNER<US>GROUP<US>SIZE<US>MTIME<US>NAME<US>TARGET`
- NAME/TARGET içinde `\n` bulunmayacağı varsayımı bu repo fixture’ları ile sınırlıdır; ileride newline fixture eklenirse format yeniden ele alınmalıdır.

---

### 3.4 Arg parsing (macOS) — ll_linux ile uyumlu alt küme

Desteklenecek flag seti (v1):
- `-d` / `--directory`
- `-n` / `--numeric-uid-gid`
- owner/group toggles (repo’daki fiili semantik ile):
  - `-g`  : owner column OFF (GNU ls `-g` uyumlu)
  - `-G`  : group column OFF (bu repoda `--no-group` ile aynı semantik)
  - `-o`  : group column OFF (GNU ls `-o` uyumlu; `--no-group` alias’ı)
  - `--no-group` : group column OFF
  - `-g -G` : owner OFF + group OFF
- `--` sentinel

v2’ye bırakılabilecek:
- `-h`, `--human-readable`, `--si`
- `-s`, `--size`

**Kritik:** `-g`, `-G`, `-g -G` ve `--no-group` semantiği, doğrudan `tests/ll/10_core.bats` içindeki `owner_variants` ve alias sanity check’lerle kilitlenmiş durumda. `ll_macos` bu varyantlarda `ll_assert_canon_equal`’dan geçecek şekilde, `ll_linux`’ün fiili davranışını birebir takip etmelidir.

---

### 3.5 Directory listing / walk (non-recursive)

Minimum davranış:
- Operand yoksa: `.` içeriği
- Operand listesi varsa:
  - file ise: kendisi
  - dir ise:
    - `-d` varsa: dir entry’nin kendisi
    - `-d` yoksa: dir içeriği (non-recursive)

Dir içeriği isim listesi:
- `ls -1` (dotfiles test fixture’larında yoksa yeter)
- dotfiles davranışı **repo’nun mevcut semantiğine göre** kesinleştirilecek.

---

### 3.6 Formatter (BSD awk) — semantik

Formatter görevleri:
1) NOW epoch:
   - `NOW_EPOCH` = `LL_NOW_EPOCH` (set değilse `systime()`)
2) Delta:
   - `dt = now - mtime_epoch`
   - `dt < 0` ise future: prefix `in` ve `dt = -dt`
3) Bucket mapping (ll_linux ile aynı olmalı):
   - `<120` sec
   - `<3600` min
   - `<172800` hrs
   - `<3888000` day
   - `<31536000` mon
   - else yr
4) Owner:
   - current user == owner ve numeric değilse: `you`
   - root tespiti: uid==0 veya owner=="root"
5) Renk:
   - time bucket renkleri + future
   - perms karakter bazlı renk
   - owner (you/root)
   - size tier
6) Hizalama:
   - canonicalizer spacing’i normalize ediyor; yine de minimum hizalama yapılacak:
     - links/owner/group/size/time alanları için width hesaplayıp pad

---

## Phase 4 — Test stratejisi: platforma göre ayrılmış suite (tests/ll_linux + tests/ll_macos)

### 4.0 Dosya taşıma/yeniden adlandırma planı (mevcut suite’ten yeni suite’lere)

**Mevcut `tests/ll/00_harness.bash` ve `tests/ll/10_core.bats` dosyaları doğrudan `tests/ll_linux/` altına taşınacaktır.**
- Tüm relative path’ler yeni konuma göre güncellenecektir.
- `tests/ll/10_core.bats` ve harness’i, GNU ls canonicalization’a ve `ll_assert_canon_equal` fonksiyonuna doğrudan bağlıdır; bu yapı yalnızca `ll_linux` suite’inde korunacaktır.
- `tests/ll/` dizini bundan sonra **GNU ls canonicalization içermeyecek**; yalnızca wrapper ve platformdan bağımsız testler içerecektir.
- Wrapper testleri için yeni dosyalar eklenecek:
  - `tests/ll/10_wrapper_stub.bats`
  - `tests/ll/fixtures/ll_stub_impl.bash`
- BSD suite yapısı için minimal placeholder dosyalar oluşturulacak:
  - `tests/ll_macos/00_harness.bash`
  - `tests/ll_macos/10_core.bats`
  - (Başlangıçta sadece preflight+skip içerebilir; dosya yapısı sabitlenmiş olur.)

**Notlar:**
- `ll_assert_canon_equal` fonksiyonu **yalnızca `ll_linux` suite’inde** kullanılacaktır.
- `tests/ll_macos` için **GNU ls referansı asla kullanılmayacak**; burada BSD stat tabanlı bir reference generator yazılacaktır.
### 4.6 Preflight fonksiyonları (soft-skip standardı)

Aşağıdaki bash fonksiyonları harness dosyalarında kullanılacak şekilde eklenmelidir:

```bash
ll_warn() {
  echo "WARNING: $*" >&2
}

ll_soft_skip() {
  ll_warn "$@"
  skip "$@"
}

ll_require_gnu_ls() {
  if ! command -v ls >/dev/null 2>&1; then
    ll_soft_skip "GNU ls not found"
    return 1
  fi
  if ! ls --time-style=+%s -d . >/dev/null 2>&1; then
    ll_soft_skip "GNU ls with --time-style=+%s required"
    return 1
  fi
}

ll_require_gawk() {
  if ! command -v gawk >/dev/null 2>&1; then
    ll_soft_skip "GNU awk (gawk) not found"
    return 1
  fi
  # Opsiyonel: belirli bir gawk özelliği gerekiyorsa burada test et.
}

ll_require_macos_userland() {
  if [ "$(uname -s)" != "Darwin" ]; then
    ll_soft_skip "Not running on macOS (Darwin)"
    return 1
  fi
  for bin in /bin/ls /usr/bin/awk /usr/bin/stat; do
    [ -x "$bin" ] || { ll_soft_skip "Required macOS binary $bin not found"; return 1; }
  done
}
```

Bu repo’nun hedefi şudur:
- Linux’ta: `ll_linux` GNU toolchain ile *tam* doğrulanmalı.
- macOS’ta: `ll_macos` Apple/BSD toolchain ile *tam* doğrulanmalı.
- macOS’ta GNU coreutils kuruluysa: geliştirici yerelde `ll_linux` suite’ini de çalıştırabilmeli.
- Linux’ta `ll_macos`’un yerelde birebir doğrulanması pratik olarak mümkün değildir; bu yüzden `ll_macos` doğrulaması CI macOS job’ına bırakılır.

Bu hedefi en az sürprizle sağlayan yaklaşım:
- `tests/ll/` altındaki *platformdan bağımsız* çekirdek testler korunur.
- Ek olarak `tests/ll_linux/` ve `tests/ll_macos/` adında iki ayrı suite klasörü eklenir.
  - `tests/ll_linux/*` yalnızca GNU `ls` (ve tercihen `gawk`) ile anlamlıdır.
  - `tests/ll_macos/*` yalnızca Apple/BSD `/bin/ls`, `/usr/bin/awk`, `/usr/bin/stat` ile anlamlıdır.

### 4.1 Bugünkü durum ve sorun
Mevcut `tests/ll/00_harness.bash` şu an baseline olarak GNU `ls --time-style=+%s` bekliyor. GNU ls yoksa testler fail olur.
Bu, macOS’ta GNU coreutils kurulu olmayan geliştiriciler için gereksiz engeldir.

### 4.2 Yeni yapı (öneri)
A) **Ortak çekirdek testler**
- `tests/ll/` altında yalnızca aşağıdaki tip testler tutulur:
  - wrapper `scripts/bin/ll` dispatch doğrulaması
  - arg parsing ve `--` sentinel davranışı (platformdan bağımsız olan kısımlar)
  - canonicalizer sözleşmesi (strip totals, ANSI strip) gibi yardımcılar

B) **Linux suite: `tests/ll_linux/`**
- Bu suite’in amacı: `ll_linux`’u GNU toolchain ile doğrulamak.
- Ön koşullar:
  - GNU `ls` ( `ls --time-style=+"%s"` desteklemeli )
  - tercihen `gawk` (match(..., array) gereksinimi)
- Davranış:
  - Ön koşullar yoksa: *warning* yaz, testleri *skip* et, suite fail etmesin.
  - Ön koşullar varsa: testler koşar ve fail edebilir.

C) **macOS suite: `tests/ll_macos/`**
- Bu suite’in amacı: `ll_macos`’u Apple/BSD userland ile doğrulamak.
- Ön koşullar:
  - `/bin/ls`, `/usr/bin/awk`, `/usr/bin/stat` mevcut olmalı.
- Davranış:
  - Bu araçlar yoksa (pratikte ancak garip/container senaryolarında): *warning* yaz, testleri *skip* et, suite fail etmesin.

### 4.3 “Soft warning, no fail” kuralı nasıl uygulanacak
Her platform suite’i için harness’in başına net bir preflight konur:
- `ll_require_gnu_ls()` / `ll_require_gawk()` gibi fonksiyonlar:
  - yoksa `echo "WARNING: ..." >&2` ve `skip "..."`
- Böylece:
  - Linux CI job: `tests/ll_linux/*` koşar; `tests/ll_macos/*` doğal olarak skip olur.
  - macOS CI job: `tests/ll_macos/*` koşar; `tests/ll_linux/*` GNU yoksa skip olur.
  - Senin macOS localinde (GNU coreutils kurulu): iki suite de koşar.

### 4.4 Baseline (reference) seçimi
Bu ayrım ile baseline problemi sadeleşir:
- `tests/ll_linux/*`: baseline = GNU `ls -l --time-style=+%s` (mevcut model).
- `tests/ll_macos/*`: baseline = BSD `stat` tabanlı “reference generator” (ls parse etmeyen, deterministik collector).

Not:
- `scripts/dev/ls-compare` ayrı bir dev aracı olarak kalabilir; fakat BATS suite için zorunlu baseline değildir.

### 4.5 Local geliştirme uyarıları (net kurallar)
- Linux üzerinde çalışırken `tests/ll_macos/*`:
  - “WARNING: ll_macos tests are not runnable on Linux locally; validated in macOS CI.”
  - suite skip.
- macOS üzerinde çalışırken GNU coreutils yoksa `tests/ll_linux/*`:
  - “WARNING: ll_linux tests require GNU coreutils (gls/gawk). Install via MacPorts/Homebrew to run locally; validated in Linux CI.”
  - suite skip.

Bu kural seti, yerelde geliştiriciye doğru beklentiyi kurar; CI’da ise her platform kendi implementasyonunu eksiksiz doğrular.

## Phase 5 — macOS BSD-only mode: PATH kontrolü

Amaç: coreutils kurulu bir mac’te bile gerçek BSD userland ile test etmek.

### 5.1 env/activate değişikliği
1) `env/activate` (ve varsa ilgili activate scriptleri) parametre alacak:
   - `LL_BSD_USERLAND=1` veya `LL_NO_GNUBIN=1`
2) Aktif olunca PATH’ten şu prefiksler çıkarılacak (varsa):
   - `/opt/local/libexec/gnubin`
   - `/usr/local/opt/coreutils/libexec/gnubin`
   - `/opt/homebrew/opt/coreutils/libexec/gnubin`
   - `/opt/local/bin` (sadece `gawk/gdate/gtouch` gibi GNU isimlerini öne çekiyorsa; dikkatli ve kontrollü kullanılmalı)
   - (gawk/gsed benzeri gnubin’ler de aynı prefikslerde olduğundan otomatik etkilenir)
- Not: `ll_macos` hiçbir koşulda `gnubin` aramaz; *mutlak path* ile `/bin/ls` ve `/usr/bin/awk` kullanır. BSD-only mode’un amacı wrapper/test harness seviyesinde sürpriz PATH etkilerini elimine etmektir.

### 5.2 Doğrulama komut seti
- `command -v ls`, `ls --version` (varsa), `command -v awk`, `command -v gawk` çıktıları kontrol edilecek

---

## Phase 6 — ll-compare revizyonu (cross-impl diff aracı)

Mevcut `scripts/dev/ls-compare` GNU ls baseline’ına çok bağlı.
Yeni ihtiyaç:
- `ll_linux` vs `ll_macos` karşılaştırması
- aynı fixture seti
- canonicalization sonrası diff raporu

### 6.1 Hedef
1) macOS’ta:
   - `ll_macos` baseline + `ll_linux` (GNU varsa) veya sadece `ll_macos` self-check
2) Linux’ta:
   - `ll_linux` baseline
   - `ll_macos` çalışmayacağı için, bu kısım sadece CI kararına göre değerlendirilecek

### 6.2 Deliverable
- İnsan-okur diff raporu üreten bir wrapper komutu (adı netleştirilecek)

---

## Phase 7 — Performance/bench

### 7.1 Ölçüm senaryoları
- küçük: ~1k entry
- büyük: ~10k entry
- her OS’te local FS üzerinde

### 7.2 Ölçüm yöntemi
- `hyperfine` varsa kullan
- yoksa `time` ile best-effort

### 7.3 Karar metriği
- hedef: `ll` ~ `ls -l`’nin ~2x civarı (mevcut beklentin)
- `ll_macos` çok yavaşsa:
  - batch `stat` çağrısı
  - collector çıktısını tek `stat` ile chunk’lama

Deliverable:
- `wip/ll-perf.md` (sayısal sonuçlar ve kullanılan komutlar)

### 7.4 Performans riski: process spawn
`ll_macos` stat-temelli olacağı için en büyük risk her entry için ayrı `stat`/`readlink` spawn maliyetidir.
- v1: correctness odaklı; önce testleri geçir.
- v2: `stat`’ı batch çalıştırma (tek çağrıda çok path) ve `readlink` çağrılarını sadece symlink’lere indirgeme.
- Kıyas metriği: `ll_macos`’un `ls -l`’ye oranla kaç kat yavaşladığı; hedef 2x civarı kalmak.

---

## Phase 8 — Unification kararı (tek ll mi, iki ll mi?)

### 8.1 Karar kriterleri
1) Correctness:
   - canonicalization sonrası fark sayısı
   - kritik edge-case’lerde fark olup olmadığı
2) Performance:
   - unified yaklaşım degrade ediyor mu?
3) Maintenance:
   - iki codepath maliyeti kabul edilebilir mi?

### 8.2 Sonuç alternatifleri
- **A)** `ll_linux` + `ll_macos` + thin wrapper ile devam
- **B)** Tek `ll`:
  - collector layer OS-specific
  - formatter layer ortak (portable awk subset)

Deliverable:
- `wip/ll-decision.md` (neden A/B seçildi, ölçümlerle)

---

## Phase 9 — CI / Makefile entegrasyonu / Stabilization

Bu fazın amacı:
- CI’da **her OS kendi implementasyonunu** tam doğrulasın.
- Local geliştirmede, geliştiricinin OS’ine göre çalışmayan suite’ler **uyarı + skip** ile “yumuşak” davransın.
- `ll` wrapper (kullanıcı yüzeyi) **her iki OS’te de** test edilsin; fakat GNU/BSD toolchain bağımlılıkları **platform suite’lerine** taşınsın.

---

### 9.1 Test klasörlerinin sorumlulukları (hangi platformda ne koşar?)

#### A) `tests/ll/*.bats` (ortak / wrapper odaklı)
Bu suite **hem Linux hem macOS** üzerinde koşar (CI ve local).

Amaç:
- `scripts/bin/ll` wrapper’ının dispatch ve override sözleşmesini test etmek.
- `--` sentinel’ın wrapper tarafından bozulmadığını test etmek (wrapper arg’ları yorumlamaz).
- “platformdan bağımsız” yardımcıların sözleşmesini test etmek (örn. canonicalizer yardımcıları gibi).

Önemli kural:
- `tests/ll/*.bats` **GNU ls/gawk** veya **BSD stat/awk** gibi platform-spesifik gereksinimlere dayanmaz.
- Bu klasördeki testler `ll_assert_canon_equal` gibi GNU baseline bekleyen harness’e bağımlı olmamalı.
  - Eğer canonical eşdeğerlik testleri gerekiyorsa, bu testler `tests/ll_linux` veya `tests/ll_macos` suite’lerine taşınır.

Örnek test başlıkları (bu suite’te yazılacak):
- `ll wrapper: LL_IMPL_PATH wins (verbatim argv forwarding)`
- `ll wrapper: LL_IMPL selects linux|macos (no uname spoof)`
- `ll wrapper: LL_SCRIPT recursion guard`
- `ll wrapper: invalid LL_IMPL exits with 2`

Not:
- Wrapper testi için en güvenilir yöntem: test sırasında `LL_IMPL_PATH`’i, arg’ları echo eden küçük bir stub executable’a yöneltip wrapper’ın arg’ları değiştirmediğini doğrulamaktır.

Ek kural:
- Bu klasörde `00_harness.bash` gibi “GNU ls baseline” bekleyen harness *kullanılmamalı*.
- Mevcut harness (GNU ls/gawk seçimi yapan) `tests/ll_linux/00_harness.bash`’e taşınmalı; `tests/ll` içindeki wrapper testleri stub tabanlı olmalı.

#### B) `tests/ll_linux/*.bats` (GNU toolchain, semantik eşdeğerlik)
Bu suite:
- Linux CI job’da **zorunlu** koşar.
- macOS’ta **GNU coreutils varsa** koşabilir.
- GNU toolchain yoksa **warning + skip** yapar, suite fail etmez.

İçerik:
- Bugünkü `00_harness.bash` + `ll_assert_canon_equal` yaklaşımı bu suite’e taşınır.
- Baseline = GNU `ls -l --time-style=+%s`.
- `LL_SCRIPT` varsayılanı wrapper `ll` olabilir (kullanıcı yüzeyi test edilir), ayrıca opsiyonel olarak doğrudan `ll_linux` hedefi de test edilebilir.

Ön koşullar (preflight):
- GNU `ls` (ls/gls veya `/opt/local/libexec/gnubin/ls`) `--time-style=+%s` desteklemeli.
- Tercihen `gawk` (yoksa bazı fast-path’ler devre dışı kalabilir; ama test suite deterministik olacak şekilde buna göre ayarlanmalı).

#### C) `tests/ll_macos/*.bats` (Apple/BSD toolchain, semantik eşdeğerlik)
Bu suite:
- macOS CI job’da **zorunlu** koşar.
- Linux’ta **yerelde doğrulanamaz** (gerçek BSD userland yok): warning + skip.

İçerik:
- Baseline = BSD `stat` tabanlı reference generator (GNU ls parse etmeyen deterministik kaynak).
- `ll_macos` mutlak path ile `/bin/ls`, `/usr/bin/awk`, `/usr/bin/stat` kullanmalı.
- `LL_SCRIPT` varsayılanı wrapper `ll` olabilir; wrapper’ın macOS’ta `ll_macos`’a dispatch ettiği zaten doğrulanmış olur.

---

### 9.2 Makefile entegrasyonu ve CI akışı (mevcut ve planlanan)

**Mevcut durumda:**
- CI pipeline’ında hem Linux hem macOS job’larında **`make test-bats`** çağrılmakta ve bu komut `tests/ll/*.bats` dosyalarını çalıştırmaktadır.
- Bu, `tests/ll/00_harness.bash` ve `tests/ll/10_core.bats`’in **her iki platformda da** çalıştırılması anlamına gelir; fakat bu dosyalar GNU ls canonicalization’a bağımlı olduğundan, macOS BSD-only hedefiyle *doğrudan çatışır*.

**Planlanan değişiklik:**
- `make test-bats` hedefi **deprecate** edilecek (ileride sadece bir alias olarak kalabilir).
- Onun yerine aşağıdaki hedefler kullanılacaktır:
  - **Linux job:**
    - `make test-ll-common && make test-ll-linux`
  - **macOS job:**
    - `make test-ll-common && make test-ll-macos`
- Geliştirici convenience için: `make test-ll-all` (her platformda tüm suite’ler, uygun olanlar skip/warn ile çalışır).
- Bu değişiklik için **ayrı bir commit** gereklidir.
- CI raporlama adımları (summary, badge, vs) **şimdilik değiştirilmeyecek**; yalnızca çağrılan test hedefleri değişecektir.

Ubuntu job toolchain notları (net):
- `ll_linux` fast-path testleri için `gawk` zorunlu kabul edilir.
- Ubuntu’da `coreutils` genelde mevcut; ancak `gawk` yoksa CI’da kur: `sudo apt-get install -y gawk`.
---

### 9.3 CI entegrasyonu (hangi job hangi testleri koşar?)

#### Linux job (Ubuntu)
Zorunlu:
- `make test-ll-common`
- `make test-ll-linux`

Beklenen davranış:
- `tests/ll_macos/*` bu job’da ya hiç çağrılmaz ya da çağrılırsa preflight ile warning+skip eder.

#### macOS job
Zorunlu:
- `make test-ll-common`
- `make test-ll-macos`

Opsiyonel (runner’da GNU coreutils varsa ya da ayrıca kuruluyorsa):
- `make test-ll-linux`
  - Bu, macOS’ta `ll_linux` regressions’ını daha erken yakalar.
  - Zorunlu olmaması daha doğru; çünkü macOS runner toolchain’i değişken olabilir.

#### 9.3.1 GitHub Actions job matrisi (öneri)

Örnek yaklaşım:
- Linux job: `make test-ll` (zaten common + linux suite)
- macOS job: `make test-ll` (zaten common + macos suite)
- Opsiyonel “macOS + GNU” job: runner’a coreutils + gawk kurup `make test-ll-all` çalıştır.

YAML (kısa iskelet):

```yaml
jobs:
  test-ubuntu:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get update
      - run: sudo apt-get install -y bats gawk coreutils
      - run: make test-ll

  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: brew install bats-core
      - run: make test-ll

  # Optional: run ll_linux semantics on macOS by installing GNU tools
  test-macos-gnu:
    runs-on: macos-latest
    if: false  # enable when you want extra coverage
    steps:
      - uses: actions/checkout@v4
      - run: brew install bats-core coreutils gawk
      - run: make test-ll-all
```

Notlar:
- test-macos job’ı GNU toolchain’e bağımlı olmamalı; ll_macos’u Apple userland ile doğrulamalı.
- test-macos-gnu “erken uyarı” içindir; başarısız olursa ll_linux regresyonu yakalanır.

---

### 9.4 `ll` wrapper olduğu için “ll” testleri neyi test eder?

`ll` kullanıcı arayüzüdür (wrapper). Dolayısıyla `tests/ll/*.bats` şu sınıf testleri hedefler:

1) Dispatch doğruluğu
- `uname -s` Darwin ise default `ll_macos`
- Darwin değilse default `ll_linux`

2) Override sözleşmesi
- `LL_IMPL_PATH` en yüksek öncelik (doğrudan exec)
- `LL_SCRIPT` legacy alias, ama wrapper’a işaret ediyorsa recursion guard devrede
- `LL_IMPL=linux|macos` seçicisi (LL_IMPL_PATH yoksa)

3) Arg forwarding
- Wrapper arg’ları yorumlamaz/dönüştürmez.
- `--` ve tricky filename arg’ları (boşluk, tab, unicode) bozulmadan implementasyona iletilir.

4) Hata mesajları ve exit code’lar
- İstenen implementasyon yoksa anlamlı hata
- Geçersiz `LL_IMPL` değeri için exit 2

Bu testler **semantik eşdeğerlik** testleri değildir; semantik eşdeğerlik platform suite’lerinin işidir.

---

### 9.4.1 `tests/ll` için stub tabanlı wrapper test iskeleti (önerilen başlangıç)

Hedef: `tests/ll/*.bats` içinde **platform bağımsız** şekilde wrapper sözleşmesini test etmek.
Bunu başarmanın en güvenli yolu, test sırasında geçici bir dizinde:
- `ll` wrapper’ın **kopyasını** üretmek,
- Aynı dizine `ll_linux` ve `ll_macos` isimli **stub** executable’lar koymak,
- Wrapper’ı bu sandbox üzerinden çalıştırmaktır.

Bu yaklaşım sayesinde:
- Gerçek `ll_linux/ll_macos` bağımlılıkları ve GNU/BSD toolchain ihtiyacı **ortak suite’e sızmaz**.
- Dispatch / override / arg-forwarding sözleşmeleri deterministik şekilde doğrulanır.

#### 9.4.1.1 Önerilen dosya yerleşimi

```
tests/ll/
  10_wrapper_stub.bats
  fixtures/
    ll_stub_impl.bash
```

#### 9.4.1.2 Stub implementasyon (tek dosya, iki rol)

`tests/ll/fixtures/ll_stub_impl.bash` içeriği:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Simple stub for wrapper tests.
# Behavior:
# - Prints a single machine-parsable line to stdout.
# - Exits with 0 unless STUB_EXIT is set.

role="${STUB_ROLE:-unknown}"

# Print role + argv in a stable format.
# We intentionally use NUL-safe-ish separators: a visible unit separator token.
printf 'STUB_ROLE=%s\n' "$role"
printf 'ARGV_COUNT=%s\n' "$#"

idx=0
for a in "$@"; do
  idx=$((idx+1))
  printf 'ARGV_%02d=%s\n' "$idx" "$a"
done

exit "${STUB_EXIT:-0}"
```

#### 9.4.1.3 BATS testi: wrapper sandbox + dispatch/override/forwarding

`tests/ll/10_wrapper_stub.bats` içeriği (başlangıç iskeleti):

```bash
#!/usr/bin/env bats

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  # Create an isolated sandbox per test.
  SANDBOX_DIR="${BATS_TEST_TMPDIR}/ll-wrapper-sandbox"
  mkdir -p "${SANDBOX_DIR}"

  # Copy the real wrapper into the sandbox so it dispatches to sandbox stubs.
  cp "${BATS_TEST_DIRNAME}/../../scripts/bin/ll" "${SANDBOX_DIR}/ll"
  chmod +x "${SANDBOX_DIR}/ll"

  # Create sandbox impl stubs as ll_linux and ll_macos.
  cp "${BATS_TEST_DIRNAME}/fixtures/ll_stub_impl.bash" "${SANDBOX_DIR}/ll_linux"
  cp "${BATS_TEST_DIRNAME}/fixtures/ll_stub_impl.bash" "${SANDBOX_DIR}/ll_macos"
  chmod +x "${SANDBOX_DIR}/ll_linux" "${SANDBOX_DIR}/ll_macos"
}

@test "ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim" {
  run env \
    STUB_ROLE=impl_path \
    LL_IMPL_PATH="${SANDBOX_DIR}/ll_linux" \
    "${SANDBOX_DIR}/ll" -- -n "a b.txt" $'a\tb.txt'

  assert_success
  assert_line --partial 'STUB_ROLE=impl_path'
  assert_line --partial 'ARGV_COUNT=4'
  assert_line --partial 'ARGV_01=--'
  assert_line --partial 'ARGV_02=-n'
  assert_line --partial 'ARGV_03=a b.txt'
  assert_line --partial $'ARGV_04=a\tb.txt'
}

@test "ll wrapper: LL_IMPL=linux selects ll_linux in the same directory" {
  run env \
    STUB_ROLE=linux \
    LL_IMPL=linux \
    "${SANDBOX_DIR}/ll" -n

  assert_success
  assert_line --partial 'STUB_ROLE=linux'
  assert_line --partial 'ARGV_01=-n'
}

@test "ll wrapper: LL_IMPL=macos selects ll_macos in the same directory" {
  run env \
    STUB_ROLE=macos \
    LL_IMPL=macos \
    "${SANDBOX_DIR}/ll" -G

  assert_success
  assert_line --partial 'STUB_ROLE=macos'
  assert_line --partial 'ARGV_01=-G'
}

@test "ll wrapper: invalid LL_IMPL returns exit 2" {
  run env \
    LL_IMPL=badvalue \
    "${SANDBOX_DIR}/ll"

  assert_failure
  [ "$status" -eq 2 ]
}

@test "ll wrapper: LL_SCRIPT recursion guard does not exec itself" {
  # If LL_SCRIPT points to the wrapper itself, it must be ignored.
  # We force a known execution path via LL_IMPL=linux and verify the stub ran.
  run env \
    STUB_ROLE=linux \
    LL_SCRIPT="${SANDBOX_DIR}/ll" \
    LL_IMPL=linux \
    "${SANDBOX_DIR}/ll" -d

  assert_success
  assert_line --partial 'STUB_ROLE=linux'
  assert_line --partial 'ARGV_01=-d'
}

@test "ll wrapper: LL_SCRIPT set but not executable returns exit 1 and error" {
  touch "${SANDBOX_DIR}/not_exec_script"
  run env \
    LL_SCRIPT="${SANDBOX_DIR}/not_exec_script" \
    "${SANDBOX_DIR}/ll"
  assert_failure
  [ "$status" -eq 1 ]
  assert_output --partial "LL_SCRIPT is set but not executable"
}

@test "ll wrapper: LL_IMPL_PATH set but not executable returns exit 1 and error" {
  touch "${SANDBOX_DIR}/not_exec_impl"
  run env \
    LL_IMPL_PATH="${SANDBOX_DIR}/not_exec_impl" \
    "${SANDBOX_DIR}/ll"
  assert_failure
  [ "$status" -eq 1 ]
  assert_output --partial "LL_IMPL_PATH is set but not executable"
}
```
### 9.6 Uygulama checklist (Cursor için sıralı işler)

1. Gerekli dizin ve yeni dosyaları oluştur:
   - `scripts/bin/ll`
   - `scripts/bin/ll_linux`
   - `scripts/bin/ll_macos`
   - `tests/ll/`
   - `tests/ll/fixtures/ll_stub_impl.bash`
   - `tests/ll/10_wrapper_stub.bats`
   - `tests/ll_linux/`
   - `tests/ll_linux/00_harness.bash`
   - `tests/ll_linux/10_core.bats`
   - `tests/ll_macos/`
   - `tests/ll_macos/00_harness.bash`
   - `tests/ll_macos/10_core.bats`
2. `tests/ll/00_harness.bash` ve `tests/ll/10_core.bats` dosyalarını `tests/ll_linux/` altına taşı/kopyala ve path’leri güncelle.
3. Wrapper stub fixture ve wrapper testlerini ekle (`tests/ll/fixtures/ll_stub_impl.bash`, `tests/ll/10_wrapper_stub.bats`).
4. macOS harness skeleton ve preflight fonksiyonlarını ekle (`tests/ll_macos/00_harness.bash`, `tests/ll_macos/10_core.bats`).
5. Makefile hedeflerini ekle/güncelle: `test-ll-common`, `test-ll-linux`, `test-ll-macos`, `test-ll`, `test-ll-all`.
6. CI workflow’larını Makefile hedeflerini çağıracak şekilde güncelle.
7. Her iki OS için yerelde aşağıdaki komutlarla doğrulama yap:
   - Linux: `make test-ll`, `make test-ll-macos`
   - macOS (GNU yok): `make test-ll`, `make test-ll-linux`
   - macOS (GNU var): `make test-ll-all`
8. Acceptance criteria (tanım aşağıda) sağlanıyor mu kontrol et.

Notlar:
- Bu iskelet, `tests/ll` suite’inin GNU/BSD toolchain bağımlılığı olmadan koşmasını sağlar.
- Dispatch testini (Darwin->ll_macos vs diğer->ll_linux) ortak suite’te zorlamıyoruz; çünkü `uname` spoof etmeye gerek kalmadan `LL_IMPL=...` ile sözleşmeyi zaten doğruluyoruz.
- Bu testler yalnızca wrapper davranışını doğrular; semantik eşdeğerlik testleri `tests/ll_linux` ve `tests/ll_macos` suite’lerinde kalır.
```

### 9.5 Stabilization checklist

- CI’da iki job da yeşil:
  - Linux: common + linux suite
  - macOS: common + macos suite
- Localde geliştirici deneyimi net:
  - Linux: `test-ll-macos` uyarı+skip
  - macOS (GNU yok): `test-ll-linux` uyarı+skip
  - macOS (GNU var): hepsi koşabilir
- `scripts/bin/ll_macos` Apple binary’lerini **mutlak path** ile kullanıyor.
- `scripts/bin/ll_linux` GNU `ls`/`gawk`’ı ya autodetect ediyor ya da `LL_CHATGPT_LS/AWK` ile zorlanabiliyor.

---

## Netleştirilmesi gereken noktalar (bu doküman varsayım yapmıyor)

Aşağıdakiler, yanlış semantik riskini sıfırlamak için **repo’daki fiili davranıştan** doğrulanacak:

1) Owner/group toggle flags:
   - `-g`, `-G`, `-g -G`, `--no-group` semantiği `tests/ll/10_core.bats` matrix ve alias sanity check’ler ile zaten kilitli.
   - `-o` semantiği bu projede **karar verildi**: `-o` == `--no-group` (group column OFF) ve GNU `ls -o` ile uyumlu bir alias.
   - Bu nedenle `ll_macos` ve `ll_linux` her iki test dünyasında da aynı davranışı vermeli:
     - bats matrix: `-g/-G/--no-group`
     - `scripts/dev/ls-compare`: ayrıca `-o`
2) dotfile davranışı:
   - default listede dotfiles var mı?
3) symlink formatı:
   - `name -> target` exact output zorunlu mu, canonicalizer neyi kabul ediyor?
4) human size (`-h/--si`) ve blocks (`-s`) hangi aşamada zorunlu?
5) GNU `date`/`touch` bağımlılığı: `00_harness.bash` içinde `ll_require_gnu_date/touch` fonksiyonları var ama bats fixture’ları `touch -t` ile üretiliyor. Planın hedefi, bats tarafında GNU `touch -d` gibi yeni bağımlılıklar eklememek; gerekiyorsa macOS tarafında eşdeğer BSD yöntemleriyle yapılmalı.
6) Yerel test uyarıları ve skip politikası:
   - Linux’ta `ll_macos` testleri: uyarı + skip (CI macOS’ta zorunlu)
   - macOS’ta GNU coreutils yoksa `ll_linux` testleri: uyarı + skip (GNU kurulursa yerelde koşabilir)
   - `ll_macos` mutlak path ile Apple binary’lerini kullanır; `ll_linux` ise GNU `ls/gawk` ile çalışır (gerekirse `LL_CHATGPT_LS` / `LL_CHATGPT_AWK` ile zorlanır)
## Acceptance Criteria (Definition of Done)

- `make test-ll` Linux CI’da geçer ve linux suite + common’ı çalıştırır.
- `make test-ll` macOS CI’da geçer ve macos suite + common’ı çalıştırır.
- `make test-ll-linux` macOS’ta GNU coreutils yoksa WARNING basar ve 0 ile çıkar (skip).
- `make test-ll-macos` Linux’ta WARNING basar ve 0 ile çıkar (skip).
- `tests/ll/*.bats` hiçbir zaman GNU `ls --time-style` veya BSD `stat` semantiğine bağımlı değildir.

---

## Cursor için Uçtan Uca Çalışma Talimatı

Cursor bu planı **adım adım ve sırasıyla** uygulamalıdır:

Her phase için:
1. Gerekli kod ve dosya değişiklikleri yapılır.
2. İlgili test hedefleri (`make test-ll-common`, `make test-ll-linux`, `make test-ll-macos`, vs) çalıştırılır.
3. Testler **yeşil** ise, ilgili commit (doğru formatta) atılır.
4. Sonra bir sonraki phase’e geçilir.

Finalde aşağıdaki koşullar sağlanmalıdır:
- **Linux CI**: yeşil (common + linux suite)
- **macOS CI**: yeşil (common + macos suite)
- Yerelde, macOS + GNU kurulu ortamda `make test-ll-all` **yeşil** geçer

Bu koşullar sağlanmadan phase tamamlanmış sayılmaz.
