# Flying Solitaire
Flying Solitaire is a horizontal scrolling video game developed using Assembly language.

## Required Software
MARS MIPS Simulator Installation Link: https://courses.missouristate.edu/KenVollmar/mars/download.htm

## Setup
### Bitmap Display Configuration
1. Navigate to _Tools_ > _Bitmap Display_.
2. Input the following display specifications:
    - **Unit width in pixels:** 4
    - **Unit height in pixels:** 4
    - **Display width in pixels:** 256
    - **Display height in pixels:** 256
    - **Base Address for Display:** 0x10008000 ($gp)
3. Click on _Connect to MIPS_.

### Keyboard Input
1. Navigate to _Tools_ > _Keyboard and Display MMIO Simulator_.
2. Click on _Connect to MIPS_.

## Gameplay
- 'A' = move left, 'S' = move down, 'D' = move right, 'W' = move up
- Avoid flying cards on the screen. With every collision, health points are deducted.
- Press 'space' to shoot
- Player cannot shoot a second time if shot is still on screen
- _Pick-up rules:_
    - Horseshoe pick-up: increases score by 10 points
    - Golden key pick-up: increases HP by 5 units (if there is the capacity to do so)
- _Grazing colour coding:_
    - Slight grazing is indicated by a orange/yellow glow of the avatar
    - Substantial collision is indicated by a blue glow of the avatar

<image src="https://user-images.githubusercontent.com/69637288/129254822-650a61b5-b48a-4124-960e-4e56ee8c9fab.png" width="300" height="300">

