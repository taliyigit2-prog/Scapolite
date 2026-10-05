[English](../../README.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Français](README.fr.md) · [Español](README.es.md)

<p align="center"><img src="../scapolite-hero.svg" alt="Scapolite" width="100%"></p>

# Scapolite

**Límites de IA, sesiones de programación, estado del Mac y caídas de servicios — directamente en la barra de menús.**

Scapolite es un panel de código abierto para la barra de menús de macOS, construido sobre [CodexBar](https://github.com/steipete/CodexBar). Conserva su amplio soporte de uso y saldos y añade sesiones recientes de Claude Code y Codex, métricas del sistema, monitorización independiente, alertas junto al notch y un bot privado de Telegram para cada usuario.

> [!IMPORTANT]
> El proyecto todavía no dispone de una cuenta Apple Developer ID. La app se compila desde el código fuente con firma ad-hoc, no está notarizada y las actualizaciones automáticas están desactivadas intencionadamente.

## Cinco vistas

| Vista | Contenido |
| --- | --- |
| **Usage** | Ventanas de cuota, reinicios, créditos, gasto y saldos de pago por uso. |
| **Sessions** | Sesiones recientes de **Claude Code** y **Codex CLI/app Codex**, con cambio a la ventana en un clic. |
| **System** | CPU, memoria, disco, red, batería, temperatura, puntuación de salud y procesos mediante `MoleWidgetCore`. |
| **Service Status** | Seguimiento independiente de OpenAI, Claude, Google AI Studio/Gemini API, Cursor, GitHub Copilot y DeepSeek. |
| **Telegram** | Tu bot y tu chat para resúmenes, caídas y recuperaciones. No existe un grupo compartido de Scapolite. |

Abre el panel con **Open Scapolite Dashboard** o <kbd>⌘</kbd><kbd>1</kbd>.

## Características destacadas

- Más de 80 proveedores y plugins heredados de CodexBar.
- Saldos para DeepSeek, OpenRouter, Mistral, DeepInfra, Moonshot, Venice, xAI y otros servicios API.
- Varias ventanas de cuota por proveedor.
- Detección local de sesiones desactivada por defecto y habilitada expresamente por el usuario.
- Comprobación de fuentes de estado oficiales cada dos minutos.
- Alerta roja en el notch ante una nueva caída y verde al recuperarse; la primera lectura solo establece la referencia.
- Token de Telegram en el Llavero de macOS y comandos aceptados únicamente desde el chat ID configurado.
- Nuevos textos de interfaz en inglés, turco, ruso, alemán, italiano, francés y español.

## Alcance de las sesiones

“CC” significa **Claude Code**, el agente de programación por línea de comandos de Anthropic. Scapolite muestra metadatos locales conocidos de Claude Code, Codex CLI y la app Codex. El motor subyacente también admite Pi/OpenCode y sesiones remotas SSH/Tailscale configuradas.

No se importan los historiales generales de claude.ai ni chatgpt.com. Al pulsar una sesión activa se trae al frente su terminal o app; una entrada antigua encontrada solo en archivos puede no tener una ventana disponible.

## Fuentes oficiales de estado

[OpenAI](https://status.openai.com/) · [Claude](https://status.claude.com/) · [Google AI Studio](https://aistudio.google.com/status) · [Cursor](https://status.cursor.com/) · [GitHub Copilot](https://copilot.statuspage.io/) · [DeepSeek](https://status.deepseek.com/)

Los servicios compatibles con Statuspage usan sus resúmenes oficiales. DeepSeek utiliza su RSS oficial y Google AI Studio el RPC público de su propia página de estado.

## Configurar Telegram

1. Crea tu propio bot con [@BotFather](https://t.me/BotFather).
2. Envía `/start` al bot desde el chat deseado.
3. Pega el token en **Scapolite Dashboard → Telegram**.
4. Usa **Discover Chat ID**, **Connect Bot** y **Send Test**.

Comandos: `/status`, `/usage`, `/sessions`, `/system`, `/refresh`, `/help`.

## Compilación

Se necesitan macOS 14+, Git y Xcode con Swift 6.2+.

```bash
git clone https://github.com/taliyigit2-prog/Scapolite.git
cd Scapolite
./Scripts/package_app.sh release
open Scapolite.app
```

## Privacidad

Las credenciales permanecen en el Mac. La detección de sesiones es opcional. Las comprobaciones de estado solo contactan con las fuentes oficiales indicadas. Telegram se comunica directamente entre el Mac y `api.telegram.org`, sin servidor intermediario de Scapolite.

Más información: [Llavero](../keychain-prompts.md), [proveedores](../providers.md), [arquitectura](../architecture.md).

## Créditos y licencia

La app se basa en [CodexBar](https://github.com/steipete/CodexBar); las métricas del sistema proceden del paquete fijado [mole-widget](https://github.com/TadelUnso/mole-widget). [Lunavect](https://github.com/lovach/Lunavect) se estudió como referencia para cambiar rápidamente de conversación; sus ilustraciones de personajes no están incluidas.

Scapolite se distribuye bajo la [licencia MIT](../../LICENSE). El [README en inglés](../../README.md) contiene la descripción técnica completa y actualizada.
