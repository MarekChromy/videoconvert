🎬 KNI Video Converter PRO
KNI Video Converter PRO je výkonný grafický nástroj pro Linux, který zjednodušuje hromadnou konverzi video souborů. Kombinuje sílu nástroje ffmpeg s přívětivým rozhraním yad, přičemž klade důraz na rychlost díky hardwarové akceleraci.

🚀 Klíčové vlastnosti
⚡ GPU Akcelerace: Podpora VA-API pro bleskové enkódování pomocí grafické karty (Intel, AMD).

🤖 Software Enkódování: Kvalitní CPU režim pro maximální kompatibilitu (libx264, libx265).

📦 Dávkové zpracování: Vyberte celou složku a nechte skript pracovat za vás.

🛠️ Flexibilní nastavení:

Výběr kodeků: H.264 nebo H.265 (HEVC).

Změna rozlišení (od 480p až po nativní 4K).

Nastavitelný video bitrate (1 Mbps – 20 Mbps).

📊 Monitoring v reálném čase: Sledování průběhu konverze a logování přímo v GUI.

📂 Organizace: Automatické vytváření výstupní složky KONVERTOVANO s časovým razítkem.

🛠️ Požadavky
Pro správný chod aplikace je nutné mít nainstalované tyto balíčky:

ffmpeg (s podporou libx264, libx265 a vaapi)

yad (pro grafické rozhraní)

Instalace závislostí:
Bash
# Ubuntu / Debian / Linux Mint
sudo apt update && sudo apt install ffmpeg yad

# Fedora
sudo dnf install ffmpeg-free yad

# Arch Linux
sudo pacman -S ffmpeg yad
📋 Použití
Stáhněte skript:

Bash
git clone https://github.com/vashu-uzivatel/kni-video-converter.git
cd kni-video-converter
Nastavte práva ke spuštění:

Bash
chmod +x konvertor.sh
Spusťte aplikaci:

Bash
./konvertor.sh
🖥️ Náhled rozhraní
Výběr souborů: Vyberete zdrojovou složku s videi.

Konfigurace: V dialogovém okně zvolíte kodek, kvalitu a režim (CPU vs. GPU).

Konverze: Sledujete terminálový výstup v grafickém okně.

⚙️ Technické detaily
Aplikace automaticky detekuje cestu k VA-API zařízení (/dev/dri/renderD128). Pokud vaše GPU podporuje hardwarové kódování, konverze bude probíhat s minimálním vytížením procesoru.

Výstupní formát: .mp4

Audio: AAC (automatický bitrate dle zvolené kvality)

Struktura: Skript zachovává původní soubory a vytváří kopie v nové složce.

👨‍💻 Autor
Marek Chromý (2026)
