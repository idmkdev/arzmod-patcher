# ARZMOD Patcher

ARZMOD Patcher для добавления большего количества возможностей (cleo, monetloader [lua] и AML [so] loader) в оригинальный лаунчер Arizona (arizona-rp.com). Создано и используется на [arzmod.com](https://arzmod.com).

## Начало работы

### Предварительные требования
Убедитесь, что у вас установлено:
- Python (версии 3.8 или выше)
- Необходимые зависимости (устанавливаются через `requirements.txt`, если применимо)
- Android SDK (build-tools)

### Шаги для использования

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/idmkdev/arzmod-patcher.git
   cd arzmod-patcher
   ```

2. Настройте параметры:
   - Откройте файл `config.py`.
   - Заполните его вашими данными (токен, бд, настройки сборки).

3. Запустите патчер:
   ```bash
   python main.py
   ```

### Теги сборки
- **`-release`**: Автоматически публикует клиент и обновляет связанные новости о клиенте.
- **`-test`**: Выполняет тестовую замену или другие тестовые действия.

Вы можете указать эти теги при запуске скрипта, чтобы определить поведение сборки.

## Примеры использования
```bash
python main.py -release
```
Этот запуск соберет APK, опубликует клиент и обновит новости (необходимо заполнить данные бд и телеграм бота в конфиге).

```bash
python main.py -test
```
Этот запуск выполнит тестовую замену.

## Created by

- [Radare](https://t.me/ryderinc) · Разработчик [ARZMOD](https://t.me/CleoArizona)

reklama arzfun dazhe tut [arzfun](https://t.me/arzfun)
