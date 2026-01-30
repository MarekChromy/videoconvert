# KNI Video Converter PRO – Linux Edition

KNI Video Converter PRO je moderní grafický nástroj pro konverzi videí na Linuxu.  
Podporuje GPU akceleraci (VA‑API), CPU enkódování, dávkové zpracování a nabízí jednoduché a přehledné GUI postavené na `yad`.

Projekt je navržen tak, aby byl rychlý, stabilní a snadno použitelný i pro běžné uživatele.

---

## Funkce

- Hardwarová akcelerace pomocí **VA‑API**
- Podpora kodeků **H.264 (AVC)** a **H.265 (HEVC)**
- **Dávkové zpracování** více souborů najednou
- Volba výstupního rozlišení (1080p, 720p, 480p, původní)
- Nastavitelný video bitrate a audio bitrate
- Volba framerate (24 / 25 / 30 / 60 fps nebo původní)
- Automatická detekce dostupnosti GPU
- Progress bar s real‑time statistikami z FFmpeg
- Podpora výstupních formátů: **MP4, MKV, AVI**
- Jednoduché GUI pomocí YAD
- Vyžaduje FFMPEG a YAD

---

## Instalace

Stáhněte `.deb` balíček z GitHub Releases a nainstalujte:

```bash
sudo dpkg -i Video Convertor 2.0.deb
sudo apt --fix-broken install
