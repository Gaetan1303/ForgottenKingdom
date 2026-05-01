Godot Import & Export Presets for Mobile

But: Godot performs texture compression during export. This document shows recommended import settings and provides an Android export preset using ETC2/ASTC guidance.

Recommended import settings (Images/Atlas)
- Compression: Lossy (use quality ~0.6 - 0.8 for UI/illustrations)
- Keep `Generate Mipmaps` ON for backgrounds, OFF for UI icons if you want crisp pixels.
- `Enable Filter` ON for smooth sprites; OFF for pixel-art.
- `Repeat` OFF for non-tiling images; ON for tiling textures.
- For atlases: prefer `Lossy` with higher quality and `Generate Mipmaps` ON.

Android Export (Godot)
- Target: GLES3 (ETC2) or GLES3+ASTC when supported
- In `Project -> Export` create an Android preset. In `Options -> Textures` choose:
  - `Compress Video/Images`: Enabled
  - `Texture Compression`: Choose `ETC2` for broad compatibility. For higher-quality builds, choose `ASTC` (smaller files, better quality) on supported devices.

Workflow suggestions
1. In Godot import dock, select an image and apply settings per recommendations.
2. For bulk application, use the `Import` dock presets in the editor (create a preset and apply to multiple files).
3. Use `Export` presets to select the compression method per export target (ETC2/ASTC).

Automated placeholders
- See `tools/generate_import_placeholders.py` which writes `.import.json` placeholder files next to assets describing the recommended import options. Use them as a checklist when applying settings inside the Godot editor.

Notes
- If you want me to run an automated conversion to KTX2 (`toktx`/`basisu`), I can install the tools and run them (requires permission). Otherwise Godot handles compression at export time.
