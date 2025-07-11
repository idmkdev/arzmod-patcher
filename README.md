# ARZMOD Patcher
ARZMOD Patcher – инструмент для добавления дополнительных возможностей (**CLEO**, **MonetLoader (Lua)** и **AML Loader**) в оригинальный лаунчер **Arizona RP** ([arizona-rp.com](https://arizona-rp.com)).  
Создано и используется на [arzmod.com](https://arzmod.com).  

## 🔧 Начало работы

### 📌 Предварительные требования (протестировано на этих версиях)
- **Python**  
- **Android SDK** (build-tools **30.0.3** & platform-tools(ADB))  
- **JDK** (**openjdk-21-jdk**)  
- **ApkTool** ([apktool_2.6.1](https://github.com/iBotPeaches/Apktool/releases/tag/v2.6.1)) 

## 🚀 Установка и запуск

### Шаги для использования

1️⃣ Клонируйте репозиторий:
   ```bash
   git clone https://github.com/idmkdev/arzmod-patcher.git
   cd arzmod-patcher
   ```

2️⃣ Для установки зависимостей Python выполните:
   ```bash
   pip install -r requirements.txt
   ```

3️⃣ Настройте параметры:
   - Откройте файл `config.py`.
   - Заполните его вашими данными (настройки сборки).

4️⃣ Запустите патчер, можно с опциями, можно без:
   ```bash
   python main.py [название файла] [опции]
   ```
   Опции:
   - `-rodina` — выбирает проект для патча RODINA_MOBILE (по умолчанию ARIZONA_MOBILE)
   - `-actual` — скачивает актуальный APK для патча
   - `-x64` — использует x64 версию приложения
   - `-arzmod` — добавляет функции ARZMOD
   - `-lockversion` — замораживает версию установленного приложения (только если приложение установлено)

   Для разработки (только если есть распакованный и пропатченный APK):
   - `-install` — устанавливает созданный APK (например если не был установлен в основном процессе)
   - `-migrate` — переход на другую архитектуру (с х32 на х64 и наоборот)
   - `-testjava` — обновляет только кастомную JAVA часть приложения
   - `-testnative` — ребилд и обновление native части (тогда нужно [постараться](native/README.md))

   Вспомогательные команды:
   - `-pytest` — запускает выполнение кода в среде скрипта
   - `-search` — поиск строки по файлам

   > 💡 Для самостоятельной компиляции native части обязательно посмотрите [инструкцию](native/README.md) (при обычной сборке APK берётся готовый билд)

## Контакты и поддержка

- [Telegram канал](https://t.me/CleoArizona)
- [Сайт](https://arzmod.com)
- [Чат в Telegram](https://t.me/cleodis)

## Created by

- [Radare](https://t.me/ryderinc) · [ARZMOD](https://t.me/CleoArizona) Developer

---

Спонсоры: [arzfun](https://t.me/arzfun) & [arizonamods](https://t.me/arizonamods) 
