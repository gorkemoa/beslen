# 🚀 Beslen App Kurulum Rehberi

## Environment Variables

Uygulamanın çalışması için aşağıdaki environment variable'ları ayarlamanız gerekiyor:

### 1. .env Dosyası (Önerilen)

Proje kök dizininde `.env` dosyası oluşturun:

```bash
# .env dosyası oluşturun
cp env.example .env
```

Sonra `.env` dosyasını düzenleyin:

```env
# Gemini AI API Key
GEMINI_API_KEY=your_gemini_api_key_here

# Development Environment
FLUTTER_ENV=development

# Debug Flags (Opsiyonel)
DEBUG_FIREBASE=false
DEBUG_AI=false
```

### 2. Dart Define (Alternatif)

Uygulamayı çalıştırırken:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

Build alırken:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

### VS Code'da Development

`.vscode/launch.json` dosyası oluşturun:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "beslen (.env)",
            "request": "launch",
            "type": "dart"
        },
        {
            "name": "beslen (dart-define)",
            "request": "launch",
            "type": "dart",
            "toolArgs": [
                "--dart-define=GEMINI_API_KEY=your_gemini_api_key_here"
            ]
        }
    ]
}
```

### Firebase Setup

1. Firebase Console'da proje oluşturun
2. Android ve iOS uygulamalarını ekleyin
3. `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını indirip ilgili klasörlere koyun
4. Firebase Authentication, Firestore ve Storage'ı etkinleştirin

## 🔒 Güvenlik

- API key'lerinizi asla kod içinde bırakmayın
- Environment variable'ları kullanın
- Git'e API key'leri commit etmeyin
- Production'da güvenli environment variable yönetimi kullanın

## 📱 Özellikler

✅ **Tamamen Dinamik Veri**
- Hiçbir statik/mock veri yok
- Tüm veriler Firebase'den geliyor
- Real-time güncellemeler

✅ **AI Tabanlı Yemek Analizi**
- Gemini AI ile fotoğraf analizi
- Otomatik besin değeri hesaplama
- Allerjen tespiti

✅ **Firebase Entegrasyonu**
- Authentication (Email + Anonymous)
- Firestore Database
- Firebase Storage
- Real-time streams

## 🛠 Kurulum Adımları

1. **Dependencies yükleyin:**
```bash
flutter pub get
```

2. **Environment variable'ları ayarlayın**

3. **Firebase'i yapılandırın**

4. **Uygulamayı çalıştırın:**
```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```

## 🔧 Sorun Giderme

**Gemini API Key Hatası:**
- Environment variable'ın doğru ayarlandığından emin olun
- API key'in geçerli olduğunu kontrol edin

**Firebase Hatası:**
- google-services.json/GoogleService-Info.plist dosyalarının doğru yerde olduğunu kontrol edin
- Firebase Console'da servislerin etkin olduğunu doğrulayın 