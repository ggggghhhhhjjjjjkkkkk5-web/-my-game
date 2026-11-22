# Kingdoms of Color — Unity Android Prototype

A separate Unity project folder for a colorful 3D castle-building and strategy game. The existing Godot project at the repository root is intentionally left untouched.

## Prototype scope (Milestone 1)
- Colorful low-poly 3D terrain and a central castle
- Isometric-style camera
- Basic mobile-friendly HUD
- Resource counter and a first build action (house)
- Runtime-generated placeholder art so the prototype has no external asset dependencies

## Open in Unity
1. Download or clone this repository.
2. In Unity Hub choose **Add > Add project from disk** and select the `UnityCastleStrategy` folder.
3. Use Unity 2022.3 LTS or a compatible newer LTS editor.
4. Open **Tools > Kingdoms of Color > Create Prototype Scene** once.
5. Open `Assets/Scenes/Main.unity` and press Play.

## Android build
The project is intended for Android. To make an APK, install Android Build Support (SDK, NDK and OpenJDK) through Unity Hub, switch the build target to Android, then build from **File > Build Settings**. A signed release build requires your own keystore.

## Current status
This is the first playable foundation, not a finished game and not yet an APK. Models are procedural placeholders; the next milestones replace them with authored stylized assets and add grid placement, economy, troops, enemy AI and combat.

## Project layout
- `Assets/Scripts/PrototypeBootstrap.cs` — prototype world, HUD and build interaction
- `Assets/Editor/CreatePrototypeScene.cs` — creates the starter scene and registers it for builds
- `Packages/manifest.json` — Unity UI dependency
