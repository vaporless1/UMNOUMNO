IOS-СБОРКА УМНО ЧЕРЕЗ GITHUB ACTIONS

1. Создайте на github.com ПРИВАТНЫЙ репозиторий (например umno-app).
2. Загрузите в него содержимое папки C:\umno БЕЗ папок build и .dart_tool
   (должны быть lib, assets, android, pubspec.yaml, test; папка ios по желанию).
3. Положите файл ios.yml в репозитории по пути .github/workflows/ios.yml.
4. Вкладка Actions -> Build iOS (unsigned IPA) -> Run workflow. Сборка 10-20 минут.
5. Когда закончится, внизу страницы запуска скачайте архив umno-ios-unsigned (внутри umno-unsigned.ipa).

Установка на iPhone без платного аккаунта Apple:
 - на компьютере установите Sideloadly (sideloadly.io) или AltStore;
 - подключите iPhone по USB, перетащите umno-unsigned.ipa в Sideloadly, войдите своим Apple ID;
 - приложение работает 7 дней, потом его нужно переустановить тем же способом;
 - на iPhone: Настройки -> Основные -> VPN и управление устройством -> доверять своему Apple ID.
Для TestFlight и App Store нужен платный аккаунт Apple Developer (99 $ в год).
