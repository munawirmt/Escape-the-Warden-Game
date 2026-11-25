# 🛡️ Escape the Warden — Offline AI Strategy Puzzle Game

An offline mobile puzzle game built using **Godot Engine (GDScript)** where players must outsmart an intelligent AI Warden that dynamically calculates pursuit routes in real time.

### 📱 Download & Play on Android
👉 **[Download Escape the Warden (Android APK)](https://drive.google.com/file/d/1UudUQAWlWZsF-StoPf8KtEHiFACGClJG/view?usp=sharing)**

Created by **[Munawir MT]**

---

### Key Technical Features
* **Real-Time A* (A-Star) Pathfinding:** Powered by `AStarGrid2D`, the AI Warden dynamically recalculates the shortest path around static and generated obstacles after every single player step.
* **Live AI Telemetry Visualizer:** Renders the AI's predicted path directly on the grid and updates its live state (`CALCULATING A*` vs. `TARGET LOCKED`) based on proximity.
* **Procedural Level Generation:** Beyond the handcrafted levels (Levels 1–5), an infinite level generator creates randomized maps while using A* path-validation to guarantee a solvable route exists.
* **100% Offline & Lightweight:** Zero external cloud APIs or internet connectivity required, packaged into a ~20MB Android APK.
* **Custom Audio & Procedural Graphics:** Features custom sound effects, synthesizer audio feedback, and touch/swipe mobile controls.

---

### 🛠️ Tech Stack
* **Game Engine:** Godot Engine 4.x
* **Language:** GDScript
* **Algorithms:** A* Pathfinding, Procedural Map Generation, Spatial Grid Mapping
* **Target Platform:** Android (APK) & Desktop

---

### 🚀 How to Run
1. Clone or download this repository.
2. Open **Godot Engine 4.x** and click **Import**.
3. Select the `project.godot` file and press **F5** (Play) to run.
