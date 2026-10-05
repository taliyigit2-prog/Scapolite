[English](../../README.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Français](README.fr.md) · [Español](README.es.md)

<p align="center"><img src="../scapolite-hero.svg" alt="Scapolite" width="100%"></p>

# Scapolite

**Limites d'IA, sessions de code, état du Mac et pannes de services — directement dans la barre des menus.**

Scapolite est un cockpit macOS open source construit sur les fondations de [CodexBar](https://github.com/steipete/CodexBar). Il conserve sa vaste prise en charge de l'utilisation et des soldes, puis ajoute les sessions récentes de Claude Code et Codex, les métriques système, une surveillance indépendante, des alertes près de l'encoche et un bot Telegram privé par utilisateur.

> [!IMPORTANT]
> Le projet ne dispose pas encore d'un compte Apple Developer ID. L'app est donc compilée depuis les sources avec une signature ad-hoc, n'est pas notariée et les mises à jour automatiques sont volontairement désactivées.

## Cinq vues

| Vue | Contenu |
| --- | --- |
| **Usage** | Fenêtres de quota, réinitialisations, crédits, dépenses et soldes pay-as-you-go. |
| **Sessions** | Sessions récentes de **Claude Code** et **Codex CLI/app Codex**, avec mise au premier plan en un clic. |
| **System** | CPU, mémoire, disque, réseau, batterie, température, score de santé et processus via `MoleWidgetCore`. |
| **Service Status** | Suivi indépendant d'OpenAI, Claude, Google AI Studio/Gemini API, Cursor, GitHub Copilot et DeepSeek. |
| **Telegram** | Votre bot et votre chat pour les résumés, pannes et rétablissements. Aucun groupe Scapolite partagé. |

Ouvrez le tableau de bord via **Open Scapolite Dashboard** ou <kbd>⌘</kbd><kbd>1</kbd>.

## Points forts

- Plus de 80 fournisseurs et plugins hérités de CodexBar.
- Soldes pour DeepSeek, OpenRouter, Mistral, DeepInfra, Moonshot, Venice, xAI et d'autres services API.
- Plusieurs fenêtres de quota par fournisseur.
- Détection locale des sessions désactivée par défaut et activée explicitement par l'utilisateur.
- Vérification des sources officielles toutes les deux minutes.
- Alerte rouge près de l'encoche lors d'une nouvelle panne et verte au rétablissement ; le premier relevé ne déclenche aucune fausse alerte.
- Jeton Telegram dans le Trousseau macOS et commandes acceptées uniquement depuis l'identifiant de chat configuré.
- Nouveaux textes d'interface en anglais, turc, russe, allemand, italien, français et espagnol.

## Portée des sessions

« CC » signifie **Claude Code**, l'agent de programmation en ligne de commande d'Anthropic. Scapolite affiche les métadonnées locales connues de Claude Code, Codex CLI et de l'app Codex. Le moteur sous-jacent prend également en charge Pi/OpenCode et les sessions distantes SSH/Tailscale configurées.

Les historiques généraux de claude.ai ou chatgpt.com ne sont pas importés. Cliquer sur une session active met son terminal ou son app au premier plan ; une entrée ancienne détectée uniquement dans des fichiers peut ne plus avoir de fenêtre.

## Sources d'état officielles

[OpenAI](https://status.openai.com/) · [Claude](https://status.claude.com/) · [Google AI Studio](https://aistudio.google.com/status) · [Cursor](https://status.cursor.com/) · [GitHub Copilot](https://copilot.statuspage.io/) · [DeepSeek](https://status.deepseek.com/)

Les services compatibles Statuspage utilisent leurs résumés officiels. DeepSeek utilise son flux RSS officiel ; Google AI Studio utilise le RPC public de sa propre page d'état.

## Configurer Telegram

1. Créez votre bot avec [@BotFather](https://t.me/BotFather).
2. Envoyez `/start` au bot depuis le chat souhaité.
3. Collez le jeton dans **Scapolite Dashboard → Telegram**.
4. Utilisez **Discover Chat ID**, **Connect Bot**, puis **Send Test**.

Commandes : `/status`, `/usage`, `/sessions`, `/system`, `/refresh`, `/help`.

## Compilation

macOS 14+, Git et Xcode avec Swift 6.2+ sont nécessaires.

```bash
git clone https://github.com/taliyigit2-prog/Scapolite.git
cd Scapolite
./Scripts/package_app.sh release
open Scapolite.app
```

## Confidentialité

Les identifiants restent sur le Mac. La détection des sessions est optionnelle. Les contrôles d'état contactent uniquement les sources officielles listées. Telegram communique directement entre le Mac et `api.telegram.org`, sans relais Scapolite.

En savoir plus : [Trousseau](../keychain-prompts.md), [fournisseurs](../providers.md), [architecture](../architecture.md).

## Crédits et licence

L'app repose sur [CodexBar](https://github.com/steipete/CodexBar) ; les métriques système proviennent du paquet épinglé [mole-widget](https://github.com/TadelUnso/mole-widget). [Lunavect](https://github.com/lovach/Lunavect) a servi de référence de recherche pour le changement rapide de conversation ; ses illustrations de personnages ne sont pas incluses.

Scapolite est distribué sous [licence MIT](../../LICENSE). Le [README anglais](../../README.md) contient la description technique complète et à jour.
