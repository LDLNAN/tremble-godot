# 🎮 Tremble (Godot Edition)

**Tremble** is a codename for a **Quake-inspired universe** of high-skill FPS games, now reimagined in the [Godot Engine](https://godotengine.org). The journey begins with **Tremble: Duel (LG - Vamp)**, a 1v1 arena shooter featuring a Beam Gun (Lightning Gun) and vampiric life steal. The project will expand to new game modes and eventually culminate in a roguelite experience.

> *Fast-paced duels, fluid movement, deep mechanics. Now powered by Godot 4 + GDScript.*

---

## 🚀 Project Overview

**Tremble: Duel (LG - Vamp)** features:

* Beam Gun (Lightning Gun) with **life steal** (e.g. 20% damage = health).
* **Physics-driven, Quake-like movement** using Godot's `CharacterBody3D` and custom ground/step logic.
* Simple 1v1 arena, **minimal UI**, and support for **networked play** (Godot Multiplayer).

### Roadmap Summary:

* **Tremble: Duel** – Beam Gun, then Rail and Rocket modes.
* **Tremble: Arena** – Clan Arena, Payload, full Quake weapon arsenal.
* **Tremble: Rogue** – Co-op roguelite with procedural levels.

Powered by:

* Godot 4.x (engine, physics, multiplayer)
* GDScript (game logic)
* [LineRenderer plugin](https://github.com/so-fluffy/LineRenderer) (beam effects)
* Modular, node-based architecture

---

## ✅ Current Features (Duel - LG - Vamp)

* 🧝 First-person controller (WASD + jump + mouse look)
* ⚡ Beam Gun (raycast, continuous fire, configurable vampirism)
* 🧱 Simple 1v1 arena map
* 🧪 **Custom hybrid movement system** (Godot CharacterBody3D + custom ground/step/air logic, Quake-like acceleration, friction, bunny hopping)
* 📊 Minimal UI (Godot UI nodes)
* ⚙️ Resource-based configuration for movement, weapons, and gamemodes
* 🌐 Multiplayer support (Godot MultiplayerSynchronizer)
* 🛠 Debug shape casting for collision diagnosis

---

## 🏃 Movement System

Tremble uses a custom hybrid movement system inspired by Quake:

- **CharacterBody3D** for core movement and collision.
- **Custom ground/step detection** using `ShapeCast3D` for robust step/ramp support.
- **Quake-like physics:** Acceleration, friction, air control, bunny hopping.
- **No phasing/overlap:** The player cannot phase into or overlap any surface.
- **Sliding:** All collisions use the actual collision normal for sliding.
- **Step/ramp support:** Player remains grounded on steps and ramps, but is ungrounded when jumping or moving up quickly.
- **Debug:** Toggle debug shape casting to visualize collision checks.

---

## 🧰 Tech Stack

| Component                     | Description                             |
| ----------------------------- | --------------------------------------- |
| 🟦 **Godot 4.x**              | Engine, physics, multiplayer            |
| 🟨 **GDScript**               | Game logic                              |
| 🟧 **LineRenderer**           | Beam/Lightning Gun visuals              |
| 🟩 **Godot Multiplayer**      | Networked play, state sync              |
| 🟪 **Resource configs**       | Data-driven movement, weapons, modes    |
| 🟫 **Node-based design**      | Modular, extensible architecture        |

---

## 🧱 Design Methodology

* 🎯 **Duel Focus First**: Start small, polish the 1v1 Beam Gun experience.
* 🔀 **Movement Depth**: Fast, fluid, configurable via resource configs.
* 🧛 **Vamp Mechanics**: Aggression rewards sustain.
* 🧹 **Modular Nodes**: Each system (e.g. `Player`, `BeamGun`) is scalable.
* 🧪 **Iterative**: Build in phases, expand steadily.
* ⚡ **Godot Performance**: Fast iteration, smooth runtime.

---

## 🧱️ Installation

### Prerequisites

* [Godot 4.x](https://godotengine.org/download)
* Git (optional, for cloning)

### Setup Instructions

1. Clone or download this repository:
   ```bash
   git clone <repository-url>
   cd scene_replication
   ```
2. Open the project in Godot 4.x.
3. Enable the LineRenderer plugin in **Project > Project Settings > Plugins**.
4. Run the project (F5) or export as needed.

#### Configuration
- Movement, weapon, and gamemode settings are defined in `.gd` resource files (see `weapon_config.gd`, `gamemode_config.gd`).
- Multiplayer is enabled by default; see `player_input.gd` and `player.tscn` for sync details.

---

### 🚯 Troubleshooting

* **LineRenderer not visible?** Ensure the plugin is enabled and the node is present in the weapon scene.
* **Multiplayer sync issues?** Check that all relevant properties are exported and included in the `MultiplayerSynchronizer` configs.
* **Movement bugs?** Use debug shape casting and check custom ground logic in `player.gd`.

---

## 🚤 Development Roadmap

### 🥇 Phase 1 – Duel: Beam Gun Vamp (2024)

* Fast movement, Beam Gun vamp weapon
* 1v1 map + networking
* UI for match info + health
* LG audio and feedback

### 🥈 Phase 2 – Duel: Rail & Rocket

* Railgun (hitscan), Rocket Launcher (splash)
* Mode-specific maps and leaderboards
* Visual/audio polish

### 🥉 Phase 3 – Arena

* Full Quake arsenal
* Gamemodes: Clan Arena, Payload
* 3–5 maps
* Up to 8-player networking
* Advanced HUD and ELO system

### 🏅 Phase 4 – Rogue

* Procedural levels + AI enemies
* Roguelite mechanics (upgrades, permadeath)
* Co-op play (2–4 players)
* Inventory UI + light story
* Score tracking

---

## 🔮 Future Plans

* New gamemodes (CTF, Instagib)
* Community map support + editor
* Cross-platform support
* Cosmetic monetization
* Esports ecosystem (1v1 + team)
* DLC or standalone release of **Tremble: Rogue**
* Consider partial open-sourcing (e.g., tools)

---

## 📜 Licensing

Tremble is **proprietary**, but uses open-source components (MIT/Apache 2.0), including:

* Godot Engine
* LineRenderer plugin

See `THIRD_PARTY_LICENSES/` or in-game credits for details.

---

## 🤝 Contributing

We're open to **tools, feedback, and assets** — not core code (yet).

### To contribute:

1. Contact the project owner.
2. Use Godot 4.x and GDScript.
3. Follow the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## 🙏 Acknowledgments

* 💪 Godot Community
* ⚡ Quake III Arena and vamp mods (inspiration)
* 🟧 so-fluffy (LineRenderer plugin)

## Notes:
- Add SOCD option for equal playing field?
