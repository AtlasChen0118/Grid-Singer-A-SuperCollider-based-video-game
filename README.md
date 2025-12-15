# Grid-Singer-A-SuperCollider-based-video-game

Grid Singer is a crude video game / SuperCollider project inspired by *Jetpack Joyride*, but where you shout into the microphone instead of holding the screen for character levitation. The louder you shout, the faster you ascend.

## Rules

### Character
The circle on the left of your screen is your character. Your objective is to survive as long as possible by navigating through incoming obstacles. The character’s vertical movement is controlled entirely by your voice: louder sounds generate upward thrust, while silence causes gravity to pull the character downward. Touching any obstacle or the roof results in immediate game over.

### Obstacles
#### Blocks
Blocks continuously spawn from the right side of the screen and move leftward at different speed. Blocks are solid blue blocks that cannot be passed through. Colliding with any solid obstacle ends the game immediately, unless you are Cloaked (see "Cloak" below).

#### Barriers
Occasionally, a cyan vertical strip (called a *barrier*) will appear. Barriers can only be destroyed if your microphone input is sufficiently loud at the moment of contact. You will know that your volume is safe to break the barrier if your character is glowing yellow. Successfully breaking a barrier removes it from the game and awards 50 bonus points. Colliding with any barriers when you are not in this state ends the game immediately, unless you are Cloaked (see "Cloak" below).

### Roof
The top of the screen contains a solid roof. Touching the roof ends the game immediately, unless you are Cloaked (see "Cloak" below). This prevents players from staying at maximum height indefinitely and encourages weaving through the obstacles.

---

## Mana and Abilities
### Mana
- Mana regenerates automatically at a rate of **1 mana every 0.15 seconds**.
- The maximum mana capacity is **100**.
- Mana regeneration continues as long as the character is alive.

### Abilities

#### Blink
- **Mana Cost:** 40  
- **Effect:** Instantly teleports the character to the location horizontally axical symmetrical to the center of the screen.
- You will be able to see where Blink will land you at all times, indicated by a faint blue shadow.

#### Cloak
- **Mana Cost:** 100  
- **Effect:** Temporarily renders the character intangible, allowing it to pass through obstacles without collision.
- Cloak will last for 2 seconds. Mind where you end the Cloak status!

Mana must be managed carefully: using abilities too frequently can leave you without enough resources when a critical situation arises.

---

## Scoring System

Your score increases through multiple actions:

- **Survival**  
  Gain **1 point every 0.1 seconds** you remain alive.

- **Breaking Barriers**  
  Destroying a cyan breaker awards **50 points**.

- **Collectibles**  
  Each green token collected awards **100 points**.

When the game ends, your final score is displayed on the Game Over screen.

---

## Technical Overview

Grid Singer is implemented entirely in **SuperCollider**, combining real-time audio analysis with a custom 2D graphics loop. The game uses:

- `SoundIn` and `Amplitude.kr` for microphone input
- OSC messaging to communicate amplitude data to the graphics layer
- A `Routine` running at approximately 30 FPS for physics, spawning, and collision handling
- Geometry-based collision detection using circle–rectangle intersection tests

All gameplay logic, rendering, and audio analysis are handled natively within SuperCollider, without relying on external game engines.

---

## How to Run

1. Install **SuperCollider** (version 3.12 or later recommended). To the download website: https://supercollider.github.io/downloads.html
2. Ensure your microphone is enabled and accessible by SuperCollider.
3. Paste the full game code into the SuperCollider editor.
4. Evaluate the entire code block. **(To evaluate in SuperCollider, Ctrl+A the entire block and press Shift+Enter.)**
5. Shout to fly — survive as long as you can.

---

## Changelog

### v0.2 — Initial Playable Release
- Core voice-controlled vertical movement using real-time microphone amplitude
- Gravity-based physics and continuous obstacle spawning
- Roof collision and instant-death mechanics
- Basic visual feedback for character state
- Mana and skills

---

## Notes
- Do not play in public. The Author is not responsible for any consequences originating from playing the game and shouting in public.
