# Erik Midnight – transparentný VS Code

## Inštalácia na novom PC

1. Nainštaluj VS Code (zaškrtni **Add to PATH**).
2. Skopíruj celý tento priečinok kamkoľvek (alebo `git clone`).
3. V tomto priečinku spusti:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup\install.ps1
   ```

   Pre konkrétny profil: `-VSProfile WebDev` (profil musí už existovať). Pre náhľad bez zápisu: `-DryRun`.
4. Vo VS Code (`Ctrl+Shift+P`): **Reload Vibrancy** → reštart → **Custom UI Style: Reload** → reštart.

Skript nainštaluje extensions a tému, doplní správne cesty k tomuto priečinku a do `settings.json` prepíše len kľúče vzhľadu (ostatné nastavenia nechá). Pôvodný súbor zálohuje ako `settings.json.bak-<dátum>`.

> Priečinok po inštalácii **nepresúvaj**. Vibrancy načítava CSS priamo odtiaľto. Ak ho presunieš, spusti skript znova.

## Kde sa čo edituje

| Čo chceš zmeniť | Kde | Po zmene |
|---|---|---|
| Priehľadnosť panelov (sidebar, editor, taby, chat, widgety) | `settings.json` → `workbench.colorCustomizations` → `"[Erik Midnight]"` | nič, prejaví sa hneď |
| Farby syntaxe a základné (nepriehľadné) farby UI | `themes/erik-midnight-color-theme.json` | prebaliť `.vsix` a preinštalovať (nižšie) |
| Veci, ktoré farby nevedia (blur, priehľadné listy, minimapa, taby bez okrajov) | `erik-dark.css` | **Reload Vibrancy** + reštart |
| Farba a sila podkladu okna (tint) | `erik-dark.json` → `background`, `opacity` | **Reload Vibrancy** + reštart |
| Celková priehľadnosť okna | `settings.json` → `vscode_vibrancy.opacity` (0–1) | **Reload Vibrancy** + reštart |
| Typ efektu (acrylic / mica / tabbed) | `settings.json` → `vscode_vibrancy.type` | **Reload Vibrancy** + reštart |
| Animácie | `settings.json` → `animations.*` | **Custom UI Style: Reload** |
| Čo inštalačný skript nastaví na novom PC | `setup/settings.template.json`, `setup/extensions.txt` | – |

`settings.json` otvoríš cez `Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)**. Otvorí sa súbor aktuálneho profilu.

### Alfa kanál (posledné 2 znaky farby)

`#181a1f33`: `00` = úplne priehľadné · `33` = 20 % · `80` = 50 % · `bf` = 75 % · `cc` = 80 % · `e6` = 90 % · `ff` = plné.

Sidebar a editor sú na `33`. Plávajúce widgety (command palette, hover, suggest) sú na `e6`, aby boli čitateľné.

### Úprava témy (.vsix)

```powershell
npx @vscode/vsce package          # vytvorí erik-midnight-<verzia>.vsix
code --install-extension .\erik-midnight-0.0.1.vsix --force
```

Pri zmene zvýš `version` v `package.json`.

## Známe veci

- **Po každom update VS Code** spusti **Reload Vibrancy** (a **Custom UI Style: Reload**). Update prepíše súbory VS Code, do ktorých sa efekt vkladá.
- Hlášku *Installation appears to be corrupt* zavri cez **Don't show again**. Je to normálne.
- **Neaktívne okno zosivie.** Na Windows 11 to robí systém (acrylic sa pri strate focusu vypne), nie je to chyba v nastaveniach.
- Nepoužívaj súčasne rozšírenie *Custom CSS and JS Loader*. Kolíduje s Vibrancy.
