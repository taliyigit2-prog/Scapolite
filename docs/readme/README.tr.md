[English](../../README.md) · [Türkçe](README.tr.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Français](README.fr.md) · [Español](README.es.md)

<p align="center"><img src="../scapolite-hero.svg" alt="Scapolite" width="100%"></p>

# Scapolite

**Yapay zekâ limitleri, kodlama oturumları, Mac sağlığı ve servis kesintileri — hepsi menü çubuğunda.**

Scapolite, [CodexBar](https://github.com/steipete/CodexBar) temeli üzerine kurulan açık kaynaklı bir macOS menü çubuğu kontrol panelidir. CodexBar'ın geniş kullanım ve bakiye desteğine son Claude Code ve Codex oturumları, canlı sistem metrikleri, bağımsız servis durumu takibi, çentik bildirimleri ve her kullanıcının kendi kurduğu özel Telegram botu eklenir.

> [!IMPORTANT]
> Projenin henüz Apple Developer ID hesabı yoktur. Bu nedenle uygulama kaynak koddan/ad-hoc imzayla paketlenir, noter onaylı değildir ve otomatik güncellemeler bilerek kapalıdır.

## Altı ana görünüm

| Görünüm | İçerik |
| --- | --- |
| **Kullanım** | Kota pencereleri, sıfırlanma zamanları, krediler, harcamalar ve kullandıkça öde bakiyeleri. |
| **Harcama** | Abonelik kotasından ayrı yerel maliyet geçmişi ve raporlar. |
| **Oturumlar** | Son **Claude Code** ve **Codex CLI/Codex uygulaması** oturumları; tek tıkla ilgili pencereye geçiş. |
| **Sistem** | `MoleWidgetCore` ile CPU, bellek, disk, ağ, pil, sıcaklık, sağlık puanı ve en yoğun işlemler. |
| **Servis Durumu** | OpenAI, Claude, Google AI Studio/Gemini API, Cursor, GitHub Copilot ve DeepSeek için bağımsız durum takibi. |
| **Telegram** | Size ait bot ve sohbet üzerinden özetler ile kesinti/iyileşme bildirimleri. Ortak Scapolite grubu yoktur. |

Paneli menü çubuğundaki **Open Scapolite Dashboard** seçeneğinden veya <kbd>⌘</kbd><kbd>1</kbd> ile açabilirsiniz.

## Öne çıkanlar

- CodexBar'dan devralınan 80'den fazla kullanım sağlayıcısı ve eklenti.
- DeepSeek, OpenRouter, Mistral, DeepInfra, Moonshot, Venice, xAI ve benzeri API tabanlı servislerde kredi/bakiye desteği.
- Sağlayıcı başına birden fazla kota penceresi.
- Gizlilik nedeniyle varsayılan olarak kapalı, kullanıcı tarafından etkinleştirilen yerel oturum keşfi.
- İki dakikada bir bağımsız servis durumu kontrolü.
- Yeni kesintide kırmızı, iyileşmede yeşil çentik bildirimi; ilk ölçüm yalnızca başlangıç değeri oluşturur.
- Telegram bot anahtarının macOS Keychain'de saklanması ve yalnızca tanımlanan sohbet kimliğinin kabul edilmesi.
- İngilizce, Türkçe, Rusça, Almanca, İtalyanca, Fransızca ve İspanyolca yeni arayüz metinleri.

## Oturum kapsamı

“CC”, Anthropic'in komut satırı kodlama aracı **Claude Code** anlamına gelir. Scapolite şu anda Claude Code ile Codex CLI/Codex masaüstü uygulamasının bilinen yerel oturum verilerini gösterir. Alttaki motor Pi/OpenCode ve yapılandırılmış SSH/Tailscale uzak oturumlarını da destekler.

Genel claude.ai veya chatgpt.com bulut sohbet geçmişleri içe aktarılmaz. Canlı bir satıra tıklamak terminal ya da uygulama penceresini öne getirir; yalnızca dosya olarak kalmış eski bir oturumun açılacak penceresi olmayabilir.

## Takip edilen servisler

- [OpenAI](https://status.openai.com/)
- [Claude](https://status.claude.com/)
- [Google AI Studio / Gemini API](https://aistudio.google.com/status)
- [Cursor](https://status.cursor.com/)
- [GitHub Copilot](https://copilot.statuspage.io/)
- [DeepSeek](https://status.deepseek.com/)

Statuspage uyumlu servisler resmi özet API'lerini, DeepSeek resmi RSS akışını, Google AI Studio ise kendi durum sayfasının kullandığı herkese açık olay RPC'sini kullanır.

## Telegram kurulumu

1. Telegram'da [@BotFather](https://t.me/BotFather) ile kendinize ait bir bot oluşturun.
2. Bildirim alacak sohbetten bota `/start` gönderin.
3. **Scapolite Dashboard → Telegram** bölümüne bot anahtarını yapıştırın.
4. **Discover Chat ID**, **Connect Bot** ve **Send Test** seçeneklerini sırayla kullanın.

Komutlar: `/status`, `/usage`, `/sessions`, `/system`, `/refresh`, `/help`.

## Derleme

macOS 14+, Git ve Swift 6.2 içeren Xcode gerekir.

```bash
git clone https://github.com/taliyigit2-prog/Scapolite.git
cd Scapolite
./Scripts/package_app.sh release
open Scapolite.app
```

Paket ad-hoc imzalanır, güncelleme akışı içermez ve mevcut Mac mimarisi için oluşturulur. İmzalı/noter onaylı yayın için ileride projeye ait Developer ID, noter bilgileri ve özel bir Sparkle anahtarı gerekecektir; CodexBar'ın upstream imza anahtarları kullanılmaz.

## Gizlilik

- Kimlik bilgileri Mac üzerinde kalır.
- Oturum keşfi kullanıcı tarafından etkinleştirilir.
- Durum kontrolleri yalnızca yukarıdaki resmi kaynaklarla bağlantı kurar.
- Telegram trafiği doğrudan Mac ile `api.telegram.org` arasındadır; aracı Scapolite sunucusu yoktur.
- Safari çerezleri gibi korumalı kaynaklar dışında Tam Disk Erişimi zorunlu değildir.

Ayrıntılar için [Keychain açıklaması](../keychain-prompts.md), [sağlayıcı belgeleri](../providers.md) ve [mimari](../architecture.md) sayfalarına bakın.

## Teşekkür ve lisans

Uygulama temeli [CodexBar](https://github.com/steipete/CodexBar), sistem metrikleri ise sabitlenmiş Swift paketi olarak [mole-widget](https://github.com/TadelUnso/mole-widget) projesinden gelir. [Lunavect](https://github.com/lovach/Lunavect) hızlı sohbet geçişi araştırmasında referans alınmıştır; karakter çizimleri Scapolite'a dahil edilmemiştir.

Scapolite [MIT Lisansı](../../LICENSE) ile dağıtılır. Tam ve güncel teknik açıklama için [İngilizce README'yi](../../README.md) kullanın.

## Menü çubuğu ve ayarlar

Üç sağlayıcı logosu yan yana gösterilebilir: üst satır kalan oturum hakkı, alt satır kalan haftalık haktır. **Ayarlar → Menü Çubuğu** bölümünde seçim ve sıra değiştirilebilir. GPT göstergesi Codex kotasıdır; ChatGPT web mesaj limiti değildir. Claude’un genel haftalık hakkı, modele özel haklarla karıştırılmaz. Bilinmeyen veya farklı süreli kotalar tire olarak gösterilir.

Servis bildirimleri varsayılan olarak açıktır; **Ayarlar → Bildirimler** bölümünden kapatılabilir ve tek bildirimle test edilebilir. Takip ve Telegram bundan etkilenmez. Harcama raporları kontrol panelindeki **Harcama** sekmesindedir. Ayarlar beş ana bölüme indirildi; sağlayıcı ayarları korunur.
