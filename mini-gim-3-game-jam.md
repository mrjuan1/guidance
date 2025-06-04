# Mini Gim #3 Game Jam

Theme: **Link**

> Bridge, chain, relationship, pathway, etc.

> Integrate theme in mechanics, setting, story, visuals (and audio, music, etc.)

> Rated on theme, fun, gameplay, audio, visuals.

---

## Name

Guidance (?)

## Idea

- In a dark world
- Can place conductive chains down
- Can link them from power sources to object requiring power
- Power sources emit a little light
- Activating them will bring more light
- This will attract inhabitants of this world
- Unlinked chains will emit a small light
- Once linked, the chains and the object they're linked to will brighten the area a little more
- The inhabitants will then move along the lit chain towards whatever it's connected to
- They will never move back to a previous link
- Unlinking a chain will unpower and item
- If the inhabitants are there when it happens, they'll run off into the darkness
- This will trigger a reset to the last link made
- Dark fogs can inhabit some already-active power lines
- If linked to the inhabitants, the fog will travel towards them and kill them
- This will also cause a reset to the previous link made
- The fog can be destroyed by deactivating the line it's inhabiting
- Otherwise they simply need to be avoided
- Each level will have an exit with a gate
- The exit must be powered to open the gate
- Move than one power-source and exit can exist in a level
- The previous level will be come an item in the new level where the inhabitants will emerge from
- This item will have as many power inputs as there were power sources in the previous level
- It will also have as many power outputs as there were exits in the level
- It will also behave externally as the previous level did
- It will become an item that can be placed down

### Opening quote

> They cannot think for themselves, thus it is our duty to think for them and help guide them to where they need to be.

## First level

Power source starts shining in the dark with a delayed visual instruction to click on it. Upon doing so, it'll get brighter and the camera will zoom out a little. Chain links will appear at the cursor and extend or retract based on how far the cursor is from the power source. The unlinked chains will hold a small light source. Additionally, a small group of characters will appear from the dark and huddle near the light of the power source. After a delay, a visual indicator will appear as a hint for where the chains should be linked to. Once linking them, they will glow bright as electricity runs through them. The characters will follow along the chain to the destination it is linked to.

After they reach the chain's destination, the camera will quickly pan down to another power source linked to something with chains and a black fog hovering over these chains. This item takes two power sources to deactivate it and destroy the dark fog that feeds off of it. Connecting the chains from the item where the characters are will allow the fog to travel along the chains and get to them, thus killing them. This will reset to the last link made.

Since the characters will never go back to a previous link, connecting directly from the power source first, then from where the characters are, will deactivate this item and destroy the fog, allowing the characters to move towards it unharmed.

Once the characters are there, one of the power sources can be unlinked, causing it to activate again, opening the gate it's linked to. The characters will then move to the gate and go through, completing the level.

## Initial requirements

- Power source
- Chain link
- Ground pin (for redirecting chains)
- Light beacon
- Override (power source that can be disabled by overriding it with two power sources)
  - This should be expandable for more inputs/outputs to represent levels
  - Also needs a little door the characters can come out of
  - Door needs to be able to close
- Exit
- Gate
- Character (idle, walking)
- Fog (black, unlit, moving/swirling, leaving small trail when moving)
- Opening text
- Arrow visual
- Click/tap visual

## Controls

- Left click to create or complete link
- Right click to cancel a new link or delete an existing link
- Mouse wheel to zoom in and out
- Middle-click-drag to pan camera around
- Middle-click and right-click-drag to rotate camera
- E to undo the last link (like loading a checkpoint)
- R to restart level
- Escape to quit

## Extras

- In-game level creation mode?
- Need more threat/obstacle ideas

## Second and subsequent levels

The characters will emerge from a new object representing the previous level and the opening they come through will close behind them. A new power source can be located nearby and activated to bring in more characters. It can be linked to the level object to join the two groups of characters. Doing this for level 1's object will cause its output to activate (since that's the established relationship between level 1's power source and exit). From here, more links can be made to move the characters towards the new level's exist while avoiding danger.
