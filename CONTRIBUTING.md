# Contributing to TÜRK-8 / TÜRK-8'e Katkıda Bulunma Rehberi

> 🇹🇷 **Türkçe rehber aşağıdadır:** [Katkıda Bulunma Rehberi (Türkçe)](#-katkıda-bulunma-rehberi-türkçe)

---

## 🌐 Contributing Guide (English)

Thank you for your interest in contributing to **TÜRK-8**! Whether you are fixing a bug, writing a new retro game or demo in Turkish assembly, improving documentation, or adding unit tests, your contributions are warmly welcome.

### 1. Core Architectural Philosophy

Before submitting code, please keep the core principles of TÜRK-8 in mind:

1. **Natural Turkish Grammar (SOV / Postfix):**
   TÜRK-8 assembly follows Turkish sentence structure where operands come first and the action verb comes last (e.g., `5 T YÜKLE`, `dongu EŞİTSE ATLA`).
2. **Zero External C Dependencies:**
   The emulator (`src/`) is written in pure **C11** (`-Wall -Wextra -std=c11`) and must compile out-of-the-box on macOS, Linux, and Windows without third-party libraries.
3. **Single-Source ISA Table (`araclar/isa.py`):**
   Opcode definitions in `include/komutlar.h`, `src/komutlar.c`, and `araclar/isa.py` must stay 100% synchronized. Our automated test suite verifies this on every run.
4. **Bilingual Documentation:**
   User-facing documentation is maintained in both English (`README.md`, `USER_MANUAL.md`) and Turkish (`OKUBENI.md`, `KULLANIM_KILAVUZU.md`).

### 2. Development Setup & Testing

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Yukselcsgn/TURK-8.git
   cd TURK-8
   ```
2. **Build the emulator:**
   ```bash
   make
   ```
3. **Run the automated test suite:**
   ```bash
   make test
   ```
   All tests in `tests/` must pass with zero warnings or errors before opening a Pull Request.

### 3. How to Submit a Pull Request

1. Fork the repository and create a new branch (`git checkout -b feat/my-feature` or `fix/my-bugfix`).
2. Make your changes and add relevant unit tests under `tests/`.
3. Verify that `make clean && make test` passes cleanly.
4. Update both English and Turkish documentation if your change affects user-facing behavior.
5. Commit your changes with a clear message and open a Pull Request against `main`.

---

## 🇹🇷 Katkıda Bulunma Rehberi (Türkçe)

**TÜRK-8** projesine katkıda bulunmak istediğiniz için teşekkürler! Hata düzeltmeleri, Türkçe assembly ile yazılmış yeni retro oyunlar/örnek programlar, dokümantasyon iyileştirmeleri veya yeni birim testleri dahil her türlü katkıya açığız.

### 1. Temel Mimari İlkeler

Kod göndermeden önce TÜRK-8'in temel tasarım ilkelerini göz önünde bulundurunuz:

1. **Doğal Türkçe Söz Dizimi (Özne/Nesne $\rightarrow$ Yüklem):**
   TÜRK-8 assembly dili, Türkçe cümle yapısına uygun olarak işlenenlerin başta, eylem bildiren komutun (yüklemin) sonda olduğu yapıyı kullanır (ör. `5 T YÜKLE`, `dongu EŞİTSE ATLA`).
2. **Sıfır Dış Bağımlılık (Saf C11):**
   Emülatör (`src/`) standart **C11** (`-Wall -Wextra -std=c11`) ile yazılmıştır; macOS, Linux ve Windows üzerinde ek kütüphane gerektirmeden derlenmelidir.
3. **Tek Kaynaklı Komut Tablosu (`araclar/isa.py`):**
   `include/komutlar.h`, `src/komutlar.c` ve `araclar/isa.py` içindeki işlem kodları ve komut boyutları birebir uyumlu olmalıdır (`make test` bunu otomatik denetler).
4. **Çift Dilli Dokümantasyon:**
   Projede hem Türkçe (`OKUBENI.md`, `KULLANIM_KILAVUZU.md`) hem İngilizce (`README.md`, `USER_MANUAL.md`) belgeler güncel tutulmaktadır.

### 2. Geliştirme Ortamı ve Testler

1. **Depoyu klonlayın:**
   ```bash
   git clone https://github.com/Yukselcsgn/TURK-8.git
   cd TURK-8
   ```
2. **Emülatörü derleyin:**
   ```bash
   make
   ```
3. **Otomatik testleri çalıştırın:**
   ```bash
   make test
   ```
   Pull Request açmadan önce `tests/` altındaki tüm testlerin hatasız geçtiğinden ve C derleyicisinin uyarı (`warning`) üretmediğinden emin olun.

### 3. Yeni Örnek Program veya Oyun Ekleme

* `programlar/` klasörüne `.asm` uzantılı Türkçe assembly programınızı ekleyebilirsiniz.
* Derlenmiş `.rom` ikili dosyalarını Git deposuna **eklemeyiniz** (`.gitignore` tarafından hariç tutulmaktadır).
* Programınızın derlenip çalıştığını doğrulayan küçük bir testi `tests/` altına eklemeniz önerilir.

### 4. Pull Request (Değişiklik İsteği) Süreci

1. Depoyu çatallayın (Fork) ve yeni bir dal oluşturun (`git checkout -b ozellik/yeni-ozellik` veya `duzeltme/hata-adi`).
2. Değişikliklerinizi yapın ve `make clean && make test` komutunun temiz geçtiğini doğrulayın.
3. Kullanıcıya dönük bir değişiklik yaptıysanız Türkçe ve İngilizce kılavuzları güncelleyin.
4. Açıklayıcı bir commit mesajıyla değişikliklerinizi kaydedip `main` dalına Pull Request açın.

