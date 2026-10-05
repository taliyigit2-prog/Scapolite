[English](../../README.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Français](README.fr.md) · [Español](README.es.md)

<p align="center"><img src="../scapolite-hero.svg" alt="Scapolite" width="100%"></p>

# Scapolite

**Limiti AI, sessioni di coding, stato del Mac e interruzioni dei servizi — direttamente nella barra dei menu.**

Scapolite è un cockpit open source per la barra dei menu di macOS, costruito sulle fondamenta di [CodexBar](https://github.com/steipete/CodexBar). Mantiene l'ampio supporto di CodexBar per utilizzo e saldi, aggiungendo sessioni recenti di Claude Code e Codex, metriche di sistema, monitoraggio indipendente dei servizi, avvisi vicino al notch e un bot Telegram privato per ogni utente.

> [!IMPORTANT]
> Il progetto non dispone ancora di un account Apple Developer ID. L'app viene quindi compilata dal sorgente con firma ad-hoc, non è notarizzata e gli aggiornamenti automatici sono disattivati intenzionalmente.

## Cinque viste

| Vista | Contenuto |
| --- | --- |
| **Usage** | Finestre di quota, reset, crediti, spesa e saldi pay-as-you-go. |
| **Sessions** | Sessioni recenti di **Claude Code** e **Codex CLI/app Codex**, con passaggio alla finestra in un clic. |
| **System** | CPU, memoria, disco, rete, batteria, temperatura, punteggio di salute e processi tramite `MoleWidgetCore`. |
| **Service Status** | Monitoraggio indipendente di OpenAI, Claude, Google AI Studio/Gemini API, Cursor, GitHub Copilot e DeepSeek. |
| **Telegram** | Il tuo bot e la tua chat per riepiloghi, interruzioni e ripristini. Nessun gruppo Scapolite condiviso. |

Apri la dashboard con **Open Scapolite Dashboard** o <kbd>⌘</kbd><kbd>1</kbd>.

## Punti di forza

- Oltre 80 provider e plugin ereditati da CodexBar.
- Saldi per DeepSeek, OpenRouter, Mistral, DeepInfra, Moonshot, Venice, xAI e altri servizi API.
- Più finestre di quota per provider.
- Rilevamento locale delle sessioni disattivato per impostazione predefinita e attivabile dall'utente.
- Controllo delle fonti di stato ufficiali ogni due minuti.
- Avviso rosso al notch per una nuova interruzione e verde al ripristino; il primo controllo crea solo la linea di base.
- Token Telegram nel Portachiavi macOS e comandi accettati soltanto dal chat ID configurato.
- Nuovi testi dell'interfaccia in inglese, turco, russo, tedesco, italiano, francese e spagnolo.

## Ambito delle sessioni

“CC” significa **Claude Code**, l'agente di coding da riga di comando di Anthropic. Scapolite mostra i metadati locali noti di Claude Code, Codex CLI e dell'app Codex. Il motore sottostante supporta anche Pi/OpenCode e sessioni remote SSH/Tailscale configurate.

Le cronologie generiche di claude.ai o chatgpt.com non vengono importate. Un clic su una sessione attiva porta in primo piano il relativo terminale o l'app; una voce più vecchia trovata solo su file potrebbe non avere una finestra da mostrare.

## Fonti di stato ufficiali

[OpenAI](https://status.openai.com/) · [Claude](https://status.claude.com/) · [Google AI Studio](https://aistudio.google.com/status) · [Cursor](https://status.cursor.com/) · [GitHub Copilot](https://copilot.statuspage.io/) · [DeepSeek](https://status.deepseek.com/)

I servizi compatibili con Statuspage usano i riepiloghi ufficiali. DeepSeek usa il feed RSS ufficiale; Google AI Studio usa l'RPC pubblico della propria pagina di stato.

## Configurare Telegram

1. Crea un bot personale con [@BotFather](https://t.me/BotFather).
2. Invia `/start` al bot dalla chat desiderata.
3. Incolla il token in **Scapolite Dashboard → Telegram**.
4. Usa **Discover Chat ID**, **Connect Bot** e **Send Test**.

Comandi: `/status`, `/usage`, `/sessions`, `/system`, `/refresh`, `/help`.

## Compilazione

Servono macOS 14+, Git e Xcode con Swift 6.2+.

```bash
git clone https://github.com/taliyigit2-prog/Scapolite.git
cd Scapolite
./Scripts/package_app.sh release
open Scapolite.app
```

## Privacy

Le credenziali restano sul Mac. Il rilevamento delle sessioni è opzionale. I controlli di stato contattano soltanto le fonti ufficiali elencate. Telegram comunica direttamente tra il Mac e `api.telegram.org`, senza un server intermediario Scapolite.

Approfondimenti: [Portachiavi](../keychain-prompts.md), [provider](../providers.md), [architettura](../architecture.md).

## Crediti e licenza

L'app si basa su [CodexBar](https://github.com/steipete/CodexBar); le metriche di sistema provengono dal pacchetto fissato [mole-widget](https://github.com/TadelUnso/mole-widget). [Lunavect](https://github.com/lovach/Lunavect) è stato studiato come riferimento per il cambio rapido delle conversazioni; le sue illustrazioni dei personaggi non sono incluse.

Scapolite è distribuito con [licenza MIT](../../LICENSE). Per la descrizione tecnica completa e aggiornata consulta il [README inglese](../../README.md).
