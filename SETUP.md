# Midnight Glass – transparent VS Code

## Installing on a new machine

1. Install VS Code (tick **Add to PATH**).
2. Clone this repository anywhere (or copy the folder).
3. From the repository folder run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup\install.ps1
   ```

   Add `-DryRun` to preview the resulting settings without writing anything.
4. In VS Code (`Ctrl+Shift+P`): **Reload Vibrancy** → restart → **Custom UI Style: Reload** → restart.

The script installs the required extensions and the theme, fills in the paths to this folder, and in `settings.json` replaces only the appearance keys (everything else is kept). The previous file is backed up as `settings.json.bak-<date>`.

It applies the setup to the Default profile and to every other profile that exists on the machine. If you create a new profile later, either base it on Default (**Profiles → New Profile → Copy from: Default**) or run the script again.

> **Don't move the folder** after installing. Vibrancy loads the CSS straight from here. If you move it, run the script again.

## Where to change what

| What you want to change | Where | After the change |
|---|---|---|
| Panel transparency (sidebar, editor, tabs, chat, widgets) | `settings.json` → `workbench.colorCustomizations` → `"[Midnight Glass]"` | nothing, applies immediately |
| Syntax colors and the base (opaque) UI colors | `themes/midnight-glass-color-theme.json` | rebuild the `.vsix` (below) |
| Things colors can't do (blur, transparent lists, minimap, borderless tabs) | `midnight-glass.css` | **Reload Vibrancy** + restart |
| Window backdrop color and strength (tint) | `midnight-glass.json` → `background`, `opacity` | **Reload Vibrancy** + restart |
| Overall window transparency | `settings.json` → `vscode_vibrancy.opacity` (0–1) | **Reload Vibrancy** + restart |
| Effect type (acrylic / mica / tabbed) | `settings.json` → `vscode_vibrancy.type` | **Reload Vibrancy** + restart |
| Animations | `settings.json` → `animations.*` | **Custom UI Style: Reload** |
| What the install script sets up on a new machine | `setup/settings.template.json`, `setup/extensions.txt` | – |

Open `settings.json` with `Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)**.

The CSS and the backdrop (`midnight-glass.css`, `midnight-glass.json`) affect every profile at once. `settings.json` belongs to one profile, so to change it everywhere either edit `setup/settings.template.json` and run the script again, or edit each profile.

### Alpha channel (last 2 characters of a color)

`#1b1b1b33`: `00` = fully transparent · `33` = 20 % · `80` = 50 % · `bf` = 75 % · `cc` = 80 % · `e6` = 90 % · `ff` = opaque.

The sidebar and editor use `33`. Floating widgets (command palette, hover, suggest) use `e6` so they stay readable.

### Rebuilding the theme (.vsix)

```powershell
npx @vscode/vsce package   # creates midnight-glass-<version>.vsix
powershell -ExecutionPolicy Bypass -File .\setup\install.ps1
```

Bump `version` in `package.json` first and delete the old `.vsix`. The script installs the newest `.vsix` into all profiles.

## Known issues

- **After every VS Code update** run **Reload Vibrancy** (and **Custom UI Style: Reload**). The update overwrites the VS Code files the effect is injected into.
- Dismiss *Installation appears to be corrupt* with **Don't show again**. It's expected.
- **An inactive window turns grey.** Windows 11 disables acrylic when the window loses focus. It's not a settings problem.
- Don't use the *Custom CSS and JS Loader* extension at the same time. It conflicts with Vibrancy.
