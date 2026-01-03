# Test Coverage Documentation

Bu dosya, `tests/` klasörü altındaki BATS testlerinin ne test ettiğini detaylı olarak açıklar. Yeni testler eklendikçe bu dosya güncellenmelidir.

## Genel Bakış

Bu proje BATS (Bash Automated Testing System) kullanarak shell script'lerini test eder. Testler, script'lerin doğru çalıştığını, fonksiyonların tanımlandığını, alias'ların oluşturulduğunu ve temel işlevselliğin korunduğunu doğrular.

**Toplam Test Sayısı:** 55 test  
**Test Dosyası Sayısı:** 4 dosya  
**Son Güncelleme:** 2024

---

## 1. alias.bats - alias.sh Testleri

**Test Dosyası:** `tests/alias.bats`  
**Kaynak Dosya:** `alias.sh`  
**Test Sayısı:** 26 test

### Test Edilen Özellikler

#### 1.1 Dosya Yüklenebilirliği
- ✅ `alias.sh` dosyasının hatasız yüklenebilmesi

#### 1.2 Fonksiyon Tanımları
Aşağıdaki fonksiyonların tanımlı olduğu test edilir:
- ✅ `mem` - Bellek kullanımını gösteren fonksiyon
- ✅ `mcd` - Dizin oluşturup içine geçen fonksiyon
- ✅ `FindFiles` - Dosya arama fonksiyonu
- ✅ `dushf` - Gizli dosyaların disk kullanımını hesaplayan fonksiyon
- ✅ `dufiles` - Belirli uzantılı dosyaların disk kullanımını hesaplayan fonksiyon
- ✅ `dusd` - Dizinlerin disk kullanımını hesaplayan fonksiyon
- ✅ `print_files` - Dosya listesini yazdıran fonksiyon
- ✅ `hs` - Geçmiş arama fonksiyonu
- ✅ `get_distro` - İşletim sistemi dağıtımını belirleyen fonksiyon

#### 1.3 Alias Tanımları
Aşağıdaki alias'ların tanımlı olduğu test edilir:
- ✅ `c` - Terminal temizleme (clear)
- ✅ `rm!` - Kalıcı silme komutu
- ✅ `fhere` - Mevcut dizinde dosya arama
- ✅ `h` - Geçmiş komutları gösterme (history)
- ✅ `hg` - Geçmişte arama yapma (history grep)
- ✅ `j` - İş listesi (jobs)
- ✅ `path` - PATH değişkenini gösterme
- ✅ `now` - Şu anki saati gösterme
- ✅ `nowtime` - Şu anki saati gösterme (now'a alias)
- ✅ `nowdate` - Şu anki tarihi gösterme
- ✅ `du` - Disk kullanımı komutu
- ✅ `myip` - IP adresini gösterme
- ✅ `ports` - Ağ portlarını gösterme

#### 1.4 Dinamik Alias Oluşturma Fonksiyonları
- ✅ `cd_aliases` fonksiyonunun oluşturduğu alias'lar:
  - `cdh` - Home dizinine geçiş
  - `.1`, `.2`, `.3`, `.4`, `.5` - Yukarı dizinlere geçiş
  - `..`, `...`, `....`, `.....`, `......` - Yukarı dizinlere geçiş
- ✅ `ls_aliases` fonksiyonunun oluşturduğu alias'lar:
  - `ls` - Liste komutu (renkli ve dizin öncelikli)
  - `la` - Tüm dosyaları listeleme
  - `ll` - Uzun format listeleme (varsa)

#### 1.5 Fonksiyon İşlevselliği
- ✅ `mcd` fonksiyonunun dizin oluşturma işlevi

### Test Kategorileri
- **Yüklenebilirlik Testleri:** 1 test
- **Fonksiyon Tanım Testleri:** 9 test
- **Alias Tanım Testleri:** 13 test
- **Dinamik Alias Testleri:** 2 test
- **İşlevsellik Testleri:** 1 test

---

## 2. bash.bats - bash.sh Testleri

**Test Dosyası:** `tests/bash.bats`  
**Kaynak Dosya:** `bash.sh`  
**Test Sayısı:** 10 test

### Test Edilen Özellikler

#### 2.1 Dosya Yüklenebilirliği
- ✅ `bash.sh` dosyasının hatasız yüklenebilmesi

#### 2.2 Prompt Ayarları
- ✅ `PS1` değişkeninin ayarlanması
- ✅ `CLICOLOR` değişkeninin 1 olarak ayarlanması
- ✅ `PROMPT_COMMAND` değişkeninin ayarlanması

#### 2.3 Geçmiş (History) Ayarları
- ✅ `HISTSIZE` değişkeninin ayarlanması ve pozitif değer olması
- ✅ `HISTFILESIZE` değişkeninin ayarlanması ve pozitif değer olması
- ✅ `HISTCONTROL` değişkeninin "ignoreboth" olarak ayarlanması
- ✅ `histappend` shell seçeneğinin etkinleştirilmesi

#### 2.4 Prompt Komut Fonksiyonları
- ✅ `NEW_PWD` değişkeninin `PROMPT_COMMAND` tarafından ayarlanması
- ✅ `bash_prompt_command` fonksiyonunun `NEW_PWD` değişkenini doğru şekilde ayarlaması
  - Home dizini için `~` kullanımı
  - Diğer dizinler için dizin adının ayarlanması

### Test Kategorileri
- **Yüklenebilirlik Testleri:** 1 test
- **Değişken Ayarları Testleri:** 6 test
- **Fonksiyon İşlevselliği Testleri:** 3 test

---

## 3. scripts_ll.bats - scripts/ll Testleri

**Test Dosyası:** `tests/scripts_ll.bats`  
**Kaynak Dosya:** `scripts/ll`  
**Test Sayısı:** 11 test

### Test Edilen Özellikler

#### 3.1 Dosya Varlığı ve Çalıştırılabilirlik
- ✅ Script dosyasının var olması
- ✅ Script dosyasının çalıştırılabilir olması

#### 3.2 Temel İşlevsellik
- ✅ Script'in mevcut dizinde hatasız çalışması
- ✅ Script'in çıktı üretmesi
- ✅ Script'in dosyaları listeleyebilmesi

#### 3.3 Komut Satırı Seçenekleri
- ✅ `-h` seçeneği (human readable - insan okunabilir boyutlar)
- ✅ `-l` seçeneği (long format - uzun format)
- ✅ `--help` seçeneği (yardım mesajı)
- ✅ `--version` seçeneği (versiyon bilgisi)
- ✅ `-d` seçeneği (dizinleri listeleme)
- ✅ `--directory` seçeneği (dizinleri listeleme)

#### 3.4 Argüman İşleme
- ✅ Dizin argümanı ile çalışabilmesi
- ✅ Mevcut dizindeki dosyaları listeleyebilmesi

### Test Kategorileri
- **Dosya Testleri:** 1 test (varlık ve çalıştırılabilirlik)
- **Temel İşlevsellik Testleri:** 3 test
- **Seçenek Testleri:** 7 test

---

## 4. scripts_dus.bats - scripts/dus Testleri

**Test Dosyası:** `tests/scripts_dus.bats`  
**Kaynak Dosya:** `scripts/dus`  
**Test Sayısı:** 8 test

### Test Edilen Özellikler

#### 4.1 Dosya Varlığı ve Çalıştırılabilirlik
- ✅ Script dosyasının var olması
- ✅ Script dosyasının çalıştırılabilir olması

#### 4.2 Temel İşlevsellik
- ✅ Script'in mevcut dizinde çalışabilmesi (hata durumları toleranslı)
- ✅ Script'in çıktı üretmesi (başarılı çalışma durumunda)

#### 4.3 Komut Satırı Seçenekleri
- ✅ `-h` seçeneği (yardım mesajı)
- ✅ `-v` seçeneği (verbose - detaylı çıktı)
- ✅ `-f` seçeneği (files only - sadece dosyalar)
- ✅ `-d` seçeneği (directories only - sadece dizinler)
- ✅ `-a` seçeneği (all - her şey)

### Test Kategorileri
- **Dosya Testleri:** 2 test
- **Temel İşlevsellik Testleri:** 2 test
- **Seçenek Testleri:** 4 test

---

## Test Kapsamı Özeti

### Dosya Bazında Kapsam

| Dosya | Test Sayısı | Kapsam |
|-------|------------|--------|
| `alias.sh` | 26 | Fonksiyonlar, alias'lar, dinamik alias oluşturma |
| `bash.sh` | 10 | Prompt ayarları, history ayarları, prompt komutları |
| `scripts/ll` | 11 | Dosya varlığı, temel işlevsellik, komut satırı seçenekleri |
| `scripts/dus` | 8 | Dosya varlığı, temel işlevsellik, komut satırı seçenekleri |
| **TOPLAM** | **55** | |

### Test Türleri

| Test Türü | Açıklama | Örnek |
|-----------|----------|-------|
| **Yüklenebilirlik** | Dosyanın hatasız yüklenebilmesi | `alias.sh can be sourced without errors` |
| **Tanım Testleri** | Fonksiyon/alias'ların tanımlı olması | `mem function is defined` |
| **Değişken Testleri** | Değişkenlerin doğru değerlere sahip olması | `PS1 is set` |
| **İşlevsellik Testleri** | Fonksiyonların beklenen şekilde çalışması | `mcd function creates directory` |
| **Seçenek Testleri** | Komut satırı seçeneklerinin çalışması | `ll script handles -h option` |
| **Argüman Testleri** | Argüman işleme | `ll script handles directory argument` |

---

## Eksik Testler / Gelecek İyileştirmeler

### Henüz Test Edilmeyen Özellikler

#### alias.sh
- [ ] `mem` fonksiyonunun gerçek çıktısı (macOS'a özgü)
- `FindFiles` fonksiyonunun gerçek arama işlevi
- `dushf`, `dufiles`, `dusd` fonksiyonlarının gerçek disk kullanımı hesaplaması
- `print_files` fonksiyonunun formatlama işlevi
- `hs` fonksiyonunun geçmiş arama işlevi
- Koşullu alias'lar (ör. `grep`, `fgrep`, `egrep` - sadece komut varsa)
- Platform-spesifik alias'lar (ör. Ubuntu için `sagi`, `update`)

#### bash.sh
- [ ] `bash_prompt` fonksiyonunun renklendirme işlevi
- `dircolors` yapılandırması
- Terminal renk desteği kontrolü

#### scripts/ll
- [ ] Renklendirme çıktısı
- Dosya izinleri formatlaması
- Boyut formatlaması (B, K, M, G, T)
- Tarih formatlaması
- Kullanıcı/grup renklendirmesi

#### scripts/dus
- [ ] Disk kullanımı hesaplama doğruluğu
- Sıralama işlevi
- Renklendirme çıktısı
- Toplam disk kullanımı gösterimi

#### Diğer Scriptler
- [ ] `scripts/dusf` - Dosya bazlı disk kullanımı script'i
- [ ] `colortable.sh` - Renk tablosu script'i
- [ ] `ll-performance.sh` - Performans test script'i
- [ ] `install_shell_settings.sh` - Kurulum script'i
- [ ] `install_shell_scripts.sh` - Script kurulum script'i

### Önerilen Test İyileştirmeleri

1. **Entegrasyon Testleri:** Fonksiyonların birlikte çalışması
2. **Hata Durumu Testleri:** Geçersiz argümanlar, eksik dosyalar
3. **Çıktı Doğrulama:** Gerçek çıktı formatının kontrolü
4. **Performans Testleri:** Büyük dosya/dizinlerle test
5. **Cross-platform Testleri:** Linux ve macOS'ta aynı davranış

---

## Test Çalıştırma

Detaylı bilgi için `tests/README.md` dosyasına bakın.

```bash
# Tüm testleri çalıştır
make test-bats

# Belirli bir test dosyasını çalıştır
bats tests/alias.bats

# Verbose modda çalıştır
bats -v tests/alias.bats
```

---

## Güncelleme Notları

Bu dosya yeni testler eklendikçe güncellenmelidir. Güncelleme yaparken:

1. İlgili bölümü bulun veya yeni bölüm ekleyin
2. Test edilen özelliği açıklayın
3. Test sayısını güncelleyin
4. "Eksik Testler" bölümünü gözden geçirin
5. Bu "Güncelleme Notları" bölümüne tarih ekleyin

**Son Güncelleme:** 2024 - İlk versiyon oluşturuldu (55 test)

