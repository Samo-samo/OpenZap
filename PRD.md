## UYGULAMA SPESİFİKASYON DÖKÜMANI (PRD)

---

## 1. Uygulamanın Temel Amacı ve Vizyonu

## Problem Tanımı

Piyasadaki mevcut akıllı televizyon (Smart TV) kumanda uygulamalarının çok büyük bir kısmı aşırı miktarda reklam barındırmakta, kullanıcı arayüzleri görsel olarak demode kalmakta ve her TV markası için kullanıcının ayrı bir uygulama indirmesini gerektirmektedir. Ayrıca, açık kaynaklı alternatiflerin çoğu son kullanıcı için teknik bilgi gerektiren, kurulumu zor yapılara sahiptir.

## Vizyon ve Çözüm

Bu proje; tamamen açık kaynaklı (open-source), reklamsız, modern tasarım trendlerine (Material You) uygun ve tek bir kod tabanıyla çoklu platformda (Cross-Platform) çalışan bir akıllı televizyon uzaktan kumanda uygulamasıdır.  
Uygulama, ilk aşamada Vestel Linux Smart TV protokolünü temel alacak; ancak mimarisi tamamen modüler (genişletilebilir) tasarlanarak ilerleyen aşamalarda Samsung, LG, Sony gibi diğer majör TV markalarını da tek bir çatı altında destekleyecektir. Kullanıcılar ek hiçbir modül indirmeden, uygulamanın hafif mimarisi sayesinde tüm TV protokollerine tek bir paketle erişebilecektir.

---

## 2. Kullanıcı Rolleri ve Deneyimi (UX/UI)

## Kullanıcı Rolü

- Ev Kullanıcısı / Son Kullanıcı: Teknik bilgiye sahip olmayan, sadece televizyonunu reklamsız, hızlı ve akıcı bir şekilde telefonundan veya bilgisayarından kontrol etmek isteyen kişiler.
- Geliştirici / Katkıda Bulunan (Açık Kaynak): GitHub üzerinden projeye yeni TV markalarının protokollerini (modüllerini) eklemek veya arayüzü geliştirmek isteyen yazılımcılar.

## Tasarım ve Deneyim Prensipleri

- Material You Entegrasyonu: Android başta olmak üzere tüm platformlarda dinamik renk şemalarını destekleyen, modern, minimalist ve gece modu uyumlu arayüz.
- Sıfır Sürtünme (Zero Friction): TV bağlantısı için kullanıcının IP adresi aramasına gerek kalmadan akıllı otomasyon süreçlerinin işletilmesi.
- İlk Kurulum Sihirbazı (Onboarding): Kullanıcıyı teknik hatalardan korumak için durum kontrolü yapan rehber ekranlar.

---

## 3. Tüm Fonksiyonlar ve Özellik Listesi (Features)

## A. Çekirdek Uzaktan Kumanda Fonksiyonları

- Standart Kumanda Seti: Yön tuşları (Yukarı, Aşağı, Sağ, Sol), Tamam (OK), Geri (Back), Ana Sayfa (Home/Menu) tuşları.
- Ses ve Kanal Kontrolleri: Sesi Aç/Kıs (Volume Up/Down), Sustur (Mute), Kanal Değiştirme (Program Up/Down) tuşları.
- Özel Vestel Tuş Kodları: Niyazi Alpay'ın açık kaynaklı projesinde tanımlanan ham TCP anahtar kodlarının (Örn: Power=`1012`, VolUp=`1016`, VolDown=`1017`) arayüz butonlarına haritalanması.

## B. Gelişmiş Özellik Modülleri

- Wake-on-LAN (WoL) - Kapalı TV'yi Açma: TV derin uyku (standby) modundayken, daha önce kaydedilen MAC adresine yerel ağ üzerinden "Sihirli Paket" (Magic Packet) göndererek televizyonun uzaktan açılmasını sağlama.
- Hızlı Uygulama Başlatıcı (Quick Launcher): TV arayüzünde gezinmeden, uygulama içindeki Netflix, YouTube, Prime Video logolarına tek tıkla basarak televizyonda ilgili uygulamayı doğrudan tetikleme.
- Uyku Zamanlayıcısı (Sleep Timer): Uygulama içinden geri sayım sayacı kurarak (Örn: 45 dakika sonra), süre bittiğinde televizyona otomatik olarak kapatma (Power) komutu gönderme.
- Çoklu Oda ve Akıllı TV Değiştirme: Evde birden fazla uyumlu TV olması durumunda, üst menüden tek tıkla TV'ler arasında geçiş yapabilme veya Wi-Fi sinyal gücüne/kayıtlı IP'ye göre otomatik odaklanma.
- QR Kod ile TV Paylaşımı: Evdeki bir cihaz TV'yi başarıyla eşleştirdiğinde, üretilen bir QR kod vasıtasıyla evdeki diğer aile üyelerinin ağ tarama süreciyle uğraşmadan TV profilini (IP ve MAC adresini) anında kendi uygulamalarına ithal edebilmesi.
- İlerleyen Aşamalar İçin Rezerve Özellikler: Dokunmatik Yüzey (Trackpad) modu ve Ana Ekran Widget'ları (İleride eklenecektir, ilk sürüme dahil edilmeyecektir).

## C. Sistem ve Altyapı Özellikleri

- Uluslararasılaştırma (i18n): İlk aşamada tam Türkçe ve İngilizce dil desteği (Tüm metinler lokalizasyon dosyalarından çekilecektir).
- Çoklu Platform (Cross-Platform) Desteği: Tek bir Flutter kod tabanı ile sırasıyla Windows, Android ve iOS platformlarına derlenebilme yeteneği.

---

## 4. Çalışma Mantığı ve İş Akışı (Flow)

## Adım 1: İlk Açılış ve Durum Doğrulama (Onboarding Flow)

1. Uygulama ilk kez açıldığında kullanıcıya bir sihirbaz gösterilir.
2. Uygulama arka planda cihazın yerel ağ durumunu kontrol eder.
3. Kullanıcıya şu 3 kritik kontrol adım adım onaylatılır:
    
    - "Cihazınız Wi-Fi ağına bağlı mı?"
    - "Televizyonunuz açık ve aynı Wi-Fi ağına bağlı mı?"
    - (Mobil cihazlar için) "Yerel ağ tarama izni verildi mi?"
    

## Adım 2: Otomatik Cihaz Keşfi ve Modül Aktivasyonu (Discovery Flow)

1. Doğrulamaların ardından uygulama, yerel ağda (LAN) tarama başlatır (Ping Discover Network / SSDP).
2. Vestel TV'lerin dinlediği portlar (Örn: `56789` veya `1986`) taranır.
3. Bir cihaz yanıt verdiğinde, cihazın IP ve MAC adresi yerel hafızaya (Secure Storage / Shared Preferences) kalıcı olarak kaydedilir.
4. Sistem mimarisi, TV'nin imzasını okur. TV "Vestel" olarak tanımlandığı an, uygulamanın çekirdek "Vestel Protokol Modülü" aktif hale gelir ve arayüz bu markaya göre şekillenir.

## Adım 3: Komut İletimi ve Soket Yönetimi (Command Flow)

1. Kullanıcı kumanda arayüzünden bir butona (Örn: Ses Açma) basar.
2. Arka planda `dart:io` kütüphanesi tetiklenerek TV'nin kayıtlı IP adresine ve ilgili portuna anlık bir TCP Soket (Socket.connect) bağlantısı açılır.
3. Niyazi Alpay'ın projesindeki ham metin protokol formatına uygun olarak (Örn: `key=1016\n`) veri paketi sokete yazılır.
4. Paket gönderildiği an (`socket.flush`), bağlantı TV'yi ve ağı yormamak için anında kapatılır (`socket.close`).

---

## 5. Kritik Kurallar ve Kısıtlamalar

- REKLAM YASAĞI: Uygulamanın hiçbir sürümünde, hiçbir platformda reklam kütüphanesi (AdMob vb.) yer almayacaktır. Kod tabanı tamamen temiz kalacaktır.
- MODÜLER MİMARİ ZORUNLULUĞU: Tüm TV markaları (Vestel, Samsung, LG vb.) tek bir soyut sınıftan (`TVInterface` veya `TVController`) türetilmelidir. Gelecekte yeni bir marka eklendiğinde ana arayüze dokunulmadan sadece o markanın sınıfı yazılabilmelidir.
- YEREL KOD BAĞIMSIZLIĞI: Marka protokolleri sadece metin tabanlı komutlar ve API istekleri içerdiği için dinamik olarak GitHub'dan indirilmeye çalışılmamalı; uygulamanın içine statik ve hafif kod blokları olarak gömülmelidir (Boyut tasarrufu için harici indirmeye gerek yoktur).
- WEB SÜRÜMÜNÜN ELENMESİ: Tarayıcıların yerel ağ kısıtlamaları (CORS ve ham TCP soket engelleri) nedeniyle projenin Web sürümü tamamen kapsam dışı bırakılmıştır. Geliştirme sırası kesin olarak: 1. Windows (Prototip) -> 2. Android -> 3. iOS olacaktır.
- PLATFORM İZİNLERİ:
    
    - Android için `AndroidManifest.xml` içinde yerel ağ ve internet izinleri eksiksiz tanımlanmalıdır.
    - iOS için `Info.plist` dosyasına "Local Network Usage" izni ve açıklaması eklenmelidir; aksi takdirde Apple ekosisteminde soketler çalışmayacaktır.
    
- BAĞLANTI ŞARTI: Uygulamanın çalışabilmesi için TV ve kontrol cihazının kesinlikle aynı lokal ağda (LAN) olması gerektiği kuralı arayüzde net bir şekilde vurgulanmalıdır.

---

