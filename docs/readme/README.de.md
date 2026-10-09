[English](../../README.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Français](README.fr.md) · [Español](README.es.md)

<p align="center"><img src="../scapolite-hero.svg" alt="Scapolite" width="100%"></p>

# Scapolite

**KI-Limits, Coding-Sitzungen, Mac-Zustand und Dienstausfälle — direkt in der Menüleiste.**

Scapolite ist ein quelloffenes macOS-Menüleisten-Cockpit auf Basis von [CodexBar](https://github.com/steipete/CodexBar). Es behält dessen breite Nutzungs- und Guthabenunterstützung und ergänzt aktuelle Claude-Code- und Codex-Sitzungen, Systemmetriken, unabhängige Statusüberwachung, Notch-Hinweise und einen privaten Telegram-Bot pro Benutzer.

> [!IMPORTANT]
> Das Projekt besitzt noch keine Apple Developer ID. Die App wird deshalb aus dem Quellcode ad-hoc signiert, ist nicht notarisiert und automatische Updates sind bewusst deaktiviert.

## Sechs Ansichten

| Ansicht | Inhalt |
| --- | --- |
| **Usage** | Kontingentfenster, Zurücksetzungen, Credits, Kosten und Pay-as-you-go-Guthaben. |
| **Ausgaben** | Lokale Kostenhistorie und Berichte getrennt vom Abonnementkontingent. |
| **Sessions** | Letzte **Claude Code**- und **Codex CLI/Codex-App**-Sitzungen mit Fokus per Klick. |
| **System** | CPU, Arbeitsspeicher, Datenträger, Netzwerk, Batterie, Temperatur, Zustandswert und Prozesse über `MoleWidgetCore`. |
| **Service Status** | Unabhängige Überwachung von OpenAI, Claude, Google AI Studio/Gemini API, Cursor, GitHub Copilot und DeepSeek. |
| **Telegram** | Eigener Bot und eigener Chat für Abfragen sowie Störungs- und Erholungsmeldungen. Keine gemeinsame Scapolite-Gruppe. |

Das Dashboard öffnet sich über **Open Scapolite Dashboard** oder <kbd>⌘</kbd><kbd>1</kbd>.

## Besonderheiten

- Über 80 von CodexBar übernommene Anbieter und Plug-ins.
- Guthaben für DeepSeek, OpenRouter, Mistral, DeepInfra, Moonshot, Venice, xAI und weitere API-Dienste.
- Mehrere Kontingentfenster je Anbieter.
- Lokale Sitzungserkennung ist aus Datenschutzgründen standardmäßig aus und wird aktiv eingeschaltet.
- Offizielle Statusabfrage alle zwei Minuten.
- Roter Notch-Hinweis bei einer neuen Störung, grüner Hinweis bei Erholung; die erste Abfrage erzeugt keinen Fehlalarm.
- Telegram-Token im macOS-Schlüsselbund und Annahme von Befehlen nur für die konfigurierte Chat-ID.
- Neue Oberflächentexte auf Englisch, Türkisch, Russisch, Deutsch, Italienisch, Französisch und Spanisch.

## Umfang der Sitzungen

„CC“ steht für **Claude Code**, den Kommandozeilen-Coding-Agenten von Anthropic. Scapolite zeigt bekannte lokale Metadaten von Claude Code sowie Codex CLI und der Codex-App. Die zugrunde liegende Engine unterstützt außerdem Pi/OpenCode und konfigurierte SSH-/Tailscale-Sitzungen.

Allgemeine Chatverläufe von claude.ai oder chatgpt.com werden nicht importiert. Ein Klick auf eine aktive Sitzung holt das zugehörige Terminal- oder App-Fenster nach vorn; ältere, nur aus Dateien erkannte Einträge besitzen möglicherweise kein Fenster.

## Offizielle Statusquellen

[OpenAI](https://status.openai.com/) · [Claude](https://status.claude.com/) · [Google AI Studio](https://aistudio.google.com/status) · [Cursor](https://status.cursor.com/) · [GitHub Copilot](https://copilot.statuspage.io/) · [DeepSeek](https://status.deepseek.com/)

Statuspage-kompatible Dienste werden über ihre offiziellen Zusammenfassungen gelesen. DeepSeek nutzt den offiziellen RSS-Feed; Google AI Studio den öffentlichen Incident-RPC seiner Statusseite.

## Telegram einrichten

1. Mit [@BotFather](https://t.me/BotFather) einen eigenen Bot erstellen.
2. Dem Bot im gewünschten Chat `/start` senden.
3. Das Token unter **Scapolite Dashboard → Telegram** einfügen.
4. **Discover Chat ID**, **Connect Bot** und **Send Test** ausführen.

Befehle: `/status`, `/usage`, `/sessions`, `/system`, `/refresh`, `/help`.

## Bauen

Erforderlich sind macOS 14+, Git und Xcode mit Swift 6.2+.

```bash
git clone https://github.com/taliyigit2-prog/Scapolite.git
cd Scapolite
./Scripts/package_app.sh release
open Scapolite.app
```

## Datenschutz

Zugangsdaten bleiben auf dem Mac. Sitzungserkennung ist optional. Statusprüfungen kontaktieren ausschließlich die oben genannten offiziellen Quellen. Telegram kommuniziert direkt zwischen dem Mac und `api.telegram.org`; ein Scapolite-Relay existiert nicht.

Weitere Informationen: [Schlüsselbund](../keychain-prompts.md), [Anbieter](../providers.md), [Architektur](../architecture.md).

## Danksagung und Lizenz

Die App basiert auf [CodexBar](https://github.com/steipete/CodexBar); Systemmetriken stammen aus dem fest angehefteten Paket [mole-widget](https://github.com/TadelUnso/mole-widget). [Lunavect](https://github.com/lovach/Lunavect) diente als Recherchebeispiel für den schnellen Gesprächswechsel; dessen Figurenzeichnungen sind nicht enthalten.

Scapolite steht unter der [MIT-Lizenz](../../LICENSE). Die vollständigste aktuelle Beschreibung enthält das [englische README](../../README.md).

## Menüleiste und Einstellungen

Bis zu drei Logos nebeneinander: oben verbleibendes Sitzungskontingent, unten Wochenkontingent. Auswahl und Reihenfolge in den Menüleisteneinstellungen. GPT bezeichnet das Codex-Kontingent, nicht ChatGPT-Nachrichtenlimits. Claudes allgemeines Wochenlimit wird nicht durch ein modellspezifisches Limit ersetzt; unbekannte Zeiträume erscheinen als Strich.

Störungsmeldungen sind standardmäßig aktiviert und lassen sich in den Benachrichtigungseinstellungen deaktivieren oder einmal testen. Überwachung und Telegram bleiben aktiv. Ausgabenberichte liegen im Dashboard. Fünf Hauptbereiche ersetzen die komplexen Einstellungen; Anbieteroptionen bleiben erhalten.
