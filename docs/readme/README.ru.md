[English](../../README.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Français](README.fr.md) · [Español](README.es.md)

<p align="center"><img src="../scapolite-hero.svg" alt="Scapolite" width="100%"></p>

# Scapolite

**Лимиты ИИ, сеансы программирования, состояние Mac и сбои сервисов — прямо в строке меню.**

Scapolite — открытая панель macOS на основе [CodexBar](https://github.com/steipete/CodexBar). Она сохраняет широкий набор источников использования и балансов CodexBar и добавляет последние сеансы Claude Code и Codex, системные метрики, независимый мониторинг сервисов, уведомления около выреза экрана и личного Telegram-бота каждого пользователя.

> [!IMPORTANT]
> У проекта пока нет Apple Developer ID. Приложение собирается из исходников с ad-hoc подписью, не нотарифицировано, а автоматические обновления намеренно отключены.

## Шесть разделов

| Раздел | Возможности |
| --- | --- |
| **Usage** | Окна квот, время сброса, кредиты, расходы и pay-as-you-go балансы. |
| **Расходы** | Локальная история стоимости и отчёты отдельно от квот подписки. |
| **Sessions** | Недавние сеансы **Claude Code** и **Codex CLI/Codex app**, переход к активному окну одним нажатием. |
| **System** | CPU, память, диск, сеть, батарея, температура, оценка здоровья и процессы через `MoleWidgetCore`. |
| **Service Status** | OpenAI, Claude, Google AI Studio/Gemini API, Cursor, GitHub Copilot и DeepSeek независимо от включённых провайдеров использования. |
| **Telegram** | Ваш бот и ваш чат для команд, сбоев и восстановления. Общей группы Scapolite нет. |

Панель открывается пунктом **Open Scapolite Dashboard** или сочетанием <kbd>⌘</kbd><kbd>1</kbd>.

## Главное

- Более 80 провайдеров и плагинов, унаследованных от CodexBar.
- Балансы DeepSeek, OpenRouter, Mistral, DeepInfra, Moonshot, Venice, xAI и других API-сервисов.
- Несколько окон квот для одного провайдера.
- Локальный поиск сеансов выключен по умолчанию и включается пользователем.
- Проверка официальных статусов каждые две минуты.
- Красное уведомление при новом сбое и зелёное при восстановлении; первоначальное состояние не вызывает тревогу.
- Токен Telegram хранится в Keychain, команды принимаются только из заданного chat ID.
- Новый интерфейс локализован на английский, турецкий, русский, немецкий, итальянский, французский и испанский.

## Какие сеансы видны

“CC” означает **Claude Code**, консольный агент Anthropic. Scapolite показывает известные локальные данные Claude Code и Codex CLI/настольного Codex. Базовый механизм также поддерживает Pi/OpenCode и настроенные удалённые сеансы SSH/Tailscale.

Истории обычных чатов claude.ai и chatgpt.com не импортируются. Нажатие на активный сеанс выводит вперёд его терминал или приложение; у старой записи, найденной только в файлах, окна может не быть.

## Официальные источники статуса

[OpenAI](https://status.openai.com/) · [Claude](https://status.claude.com/) · [Google AI Studio](https://aistudio.google.com/status) · [Cursor](https://status.cursor.com/) · [GitHub Copilot](https://copilot.statuspage.io/) · [DeepSeek](https://status.deepseek.com/)

Сервисы Statuspage читаются через официальные сводки, DeepSeek — через официальный RSS, Google AI Studio — через публичный RPC собственной страницы статуса.

## Telegram

1. Создайте собственного бота через [@BotFather](https://t.me/BotFather).
2. Отправьте боту `/start` из нужного чата.
3. Вставьте токен в **Scapolite Dashboard → Telegram**.
4. Нажмите **Discover Chat ID**, затем **Connect Bot** и **Send Test**.

Команды: `/status`, `/usage`, `/sessions`, `/system`, `/refresh`, `/help`.

## Сборка

Нужны macOS 14+, Git и Xcode со Swift 6.2+.

```bash
git clone https://github.com/taliyigit2-prog/Scapolite.git
cd Scapolite
./Scripts/package_app.sh release
open Scapolite.app
```

## Конфиденциальность

Учётные данные остаются на Mac. Поиск сеансов включается отдельно. Проверки статуса обращаются только к официальным адресам выше. Telegram работает напрямую между Mac и `api.telegram.org`, без сервера-посредника Scapolite.

Подробнее: [Keychain](../keychain-prompts.md), [провайдеры](../providers.md), [архитектура](../architecture.md).

## Благодарности и лицензия

Основа приложения — [CodexBar](https://github.com/steipete/CodexBar), системные метрики — закреплённый пакет [mole-widget](https://github.com/TadelUnso/mole-widget). [Lunavect](https://github.com/lovach/Lunavect) использовался как исследовательский ориентир для переключения разговоров; его иллюстрации персонажей не включены.

Scapolite распространяется по [лицензии MIT](../../LICENSE). Самое полное актуальное описание находится в [английском README](../../README.md).

## Строка меню и настройки

До трёх логотипов рядом: сверху оставшаяся квота сеанса, снизу недельная. Выбор и порядок — в настройках строки меню. GPT означает квоту Codex, не лимит сообщений ChatGPT. Общая недельная квота Claude не заменяется квотой отдельной модели; неизвестные периоды показываются как тире.

Уведомления о сбоях включены по умолчанию; их можно отключить или проверить одним уведомлением в настройках уведомлений. Мониторинг и Telegram продолжают работать. Отчёты расходов перенесены в панель. Настройки упрощены до пяти основных разделов; настройки провайдеров сохранены.
