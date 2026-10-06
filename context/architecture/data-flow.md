<!--
What this file answers: the happy-path walkthrough of the project's primary flow, from user input (or request) to final output.
When to update: any change that alters the sequence, adds a step, or changes where a step runs. Same turn as the code change.
-->

# Data flow

## Primary flow: produce → sell → upgrade → grow the world

1. **Harvest:** the player walks over a field and picks ripe crops (`harvest`) into the carried stack, up to `S.cap`. Crops are only picked when something can use them.
2. **Process:** the stack is dropped on a machine's in-pad, into its hopper. Animals or stations turn the input into output on the machine's tray every `period` seconds. A conveyor (`feed`) or a helper automates this step.
3. **Sell:** output is carried to a counter's drop. Customers queue with a patience ring, are served, and leave coins or votes in the counter's cash pocket. A full pocket spills, which is where the bank collector comes in.
4. **Buy:** standing on a pad pays into it a little at a time. When it's fully paid, `applyPad` applies its effect: an unlock, a helper, more units, a price change, a vehicle, a gun, the chapter gate, and so on. Then `computeReveal` clears the fog, and the game saves.
5. **The chapter gate** opens the next area. In the political chapters gates cost votes. The candidate wins at 270 electoral votes, then gets the ending, and can retire (prestige).
6. **The threat loop:** an unserved customer turns into a zombie (faster at night). It pathfinds to the player, winds up, and bites, knocking out items or coins. Shooting it with carried products cures it and pays a bonus.

## Failure paths
- **Stuck player or helper:** the unstick safety net moves them to the nearest open spot.
- **localStorage blocked:** the try/catch means the game keeps running without saving.
- **Cloud save:** it's skipped when `window.claude` is missing (standalone).

## Trust boundaries
None. It's a client-only game, and the only external resource is the Google font.
