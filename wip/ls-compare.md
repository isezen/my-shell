# ls-compare.md

# ls-compare — Tanım, Hedef, Sınırlar

## Amaç
ls-compare’ın amacı:
- Bir “referans” komutun çıktısını (temel: `ls -l --color --time-style=+"%s"`)
- Karşılaştırılacak script(ler)in çıktısıyla (örn. ll-chatgpt)
- Aynı kanonik formata getirip birebir karşılaştırmak.

Bu sayede:
- ll-chatgpt’nin “sunum” farkları (renk, spacing) testte gürültü oluşturmaz
- Semantik hatalar (kolon kayması, isim kırpma, yanlış zaman hesabı, opsiyonların yanlış ele alınması) net yakalanır.

## Temel Referans (Baseline)
Baseline komut:
`ls -l --color --time-style=+"%s"` + test-case argümanları

Bu baseline:
- zamanı epoch saniye olarak verir
- owner/group alanları flag’lere göre değişir (ls tarafında bu flag’ler baseline’a da uygulanır)

## ls-compare Ne Yapıyor
1) Fixture dizini kurar (dosyalar, özel isimler, symlink, fifo, izin bitleri).
2) Mtime’ları sabitler (deterministik zaman farkı için).
3) “now” zamanını sabitler (env üzerinden).
4) Her test case için:
   - Baseline `ls ...` çıktısını alır
   - Baseline çıktısını ll-benzeri kanonik formata çevirir:
     - epoch -> relative time
     - toplam/total satırını atar
     - “user adını” normalize edebilir (örn. local user -> `you`)
   - Script çıktısını alır (ll-chatgpt)
   - Script çıktısını kanonik formata çevirir:
     - ANSI/control strip
     - toplam/total satırını atar
     - spacing normalize (yalnız token prefix)
     - (gerekirse) script’in bastığı opsiyonel epoch gibi “fazlalıkları” yok sayar
   - Kanonik çıktıların eşitliğini kontrol eder.
5) Fail durumunda side-by-side diff gösterir.

## ls-compare Ne Yapmamalı (Sınırlar)
- ls-compare, “script davranışı”nı maskelememelidir.
  - Örn: script bir dosya adını kaybediyorsa, ls-compare bunu “tahmin edip” geri koymamalı.
  - Örn: script relative time’ı yanlış hesaplıyorsa, ls-compare onu “script gibi” yanlış hesaplayıp eşleştirmeye çalışmamalı.
- Amaç “eşleştirmek” değil, “semantik uyumu test etmek” olmalı.
- Strip/sanitize yalnızca “sunum gürültüsü” içindir:
  - ANSI renk kodları
  - bazı kontrol karakterleri (örn. CR)
  - `total/toplam` header satırı

## Kanonik Format İlkesi
Karşılaştırma, aşağıdaki mantıkla yapılır:
- Baseline (ls) çıktısı ll-benzeri bir forma dönüştürülür
- Script (ll-chatgpt) çıktısı da aynı forma normalize edilir
- Eşitlik bu form üzerinde aranır

Bu yaklaşım “ll-chatgpt output’u ls -l ile birebir aynı olmalı” gibi imkansız bir hedef koymaz.
Buna karşın “ll-chatgpt’nin semantik olarak ls’den türetilebilir olması” şartını dayatır.

## Debug/Diagnostik
- `--show-ansi`:
  - ANSI kaçışlarını görünür hale getirerek farkların kökenini bulmaya yardım eder
- `--fail-only`:
  - sadece failing testleri basar
- `--only <TEST>`:
  - sadece ilgili test case’i çalıştırır

## Başarı Kriteri
- Renksiz/kanonik çıktılar tüm test case’lerde baseline ile birebir eşleşmelidir.
- Eşleşmiyorsa bu, genellikle ll-chatgpt tarafında:
  - kolon kayması / yanlış argüman mapping
  - filename parsing bug
  - zaman hesabında “now” referansının bozulması
  - bazı modlarda ekstra alan basılması
gibi semantik bir probleme işaret eder.

## Cross-Impl Compare (ll_linux vs ll_macos)
- `scripts/dev/ll-compare ll_linux ll_macos` ile iki implementasyonun çıktıları karşılaştırılır.
- Determinism: `LC_ALL=C`, `TZ=UTC`, `LL_NOW_EPOCH=1577836800` (env ile override edilebilir).
- `LL_CHATGPT_FAST=1` ile hızlı yol zorlanır (ll_linux için).
