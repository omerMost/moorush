# 2026-10-03 (evening) — v6 vehicles, harbor, robbers → fun diagnosis → v7 zombies, day and night → v8 chase fix

> **Imported** from claude.ai chat "Creating a game from an ad" (https://claude.ai/chat/645c8425-a2a0-41fb-9c03-2908bc0973e1, shared copy https://claude.ai/share/619469d2-2ba6-44c5-bf35-61d6c89a62d0). The work happened before this repo existed, and the times are the chat's real message times (local +03:00). The code lived in the claude.ai artifact https://claude.ai/artifact/YFNZ2jPt6E6tRczYqF74EY and is now `prototype/index.html`.

## What happened
- **v6:** the user said "car store not working, no delivery improvement… vehicles… water area only by boats… money should get much more expensive… funny robbers… THE GAME SHOULD BE FUNNIER. and tests should be made."
  - **A "every counter keeps selling unattended" test** found 2 dead counters: the car dealer (fixed with a Bolt runner) and the fruit stand (fixed with a Fruit stocker).
  - **Vehicles** at the vehicle shop: bicycle 300 (1.35×), scooter 8k (1.7×), car 250k (2.1×), sports car 20M (2.6×), and jetpack 2B (3.2×, flies). There's also a **guard dog**.
  - **The Harbor:** a lake that opens in chapter 2, with a **Rowboat** needed to go on the water. Fishing, a fish market, a sushi bar, a pearl reef and a jewelry island, plus a speedboat.
  - **A steep economy:** a price multiplier PM per chapter of 1 → 1000. The best item goes from 6 coins in ch1 to 2M in ch9.
  - **Robbers:** Rocky Raccoon, Sneaky Pete, Tax Man, and a Rival candidate who steals votes. They hide in bushes and chase you. If they catch you, coins spill and you grab them back; you can tackle a robber to recover the sack.
  - Tests: 15/15 features ×3, a bot reached President with robbers on (about 2.5 h), and a v5 save loaded.
- **Fun diagnosis:** the user said "the game is just not fun. But the ad looks fun. So what is it?" My answer: the ad sells abundance and speed. Too much walking, small stacks, rare rewards, no juice, no urgency. I proposed a "fun pass."
  - **The user rejected copying the ad**, and proposed: customers who wait too long **turn into zombies** and chase you, weapons, day and night, and a 50%-cut money collector for full cash pockets with a red arrow. I added more ideas, and the user said **"I love all your ideas make them. I trust you to fully build it and test it."**
- **v7, day and night plus zombies:**
  - **Zombies:** visible turning, with a ring going green → orange → red. Bites knock items or coins out of your hands, and zombies eat dropped coins.
  - **Weapons** at the Farm armory (Milk squirter 100 → Egg launcher → Popcorn cannon → Confetti cannon) that use your carried stack as ammo. Curing a zombie pays double, or triple on a blood moon.
  - **Time:** a 5-minute day (morning, midday, evening rush, night with lamps). A **blood moon** every 3rd night with a horde.
  - **Defenses:** scarecrow turrets and floodlights. **Money pockets** with a red arrow at 80%, and bank collectors taking 50 → 30 → 15%.
  - **Customers:** VIPs, grannies, the food critic, and star ratings. **Daily goals.**
  - **Night-only businesses:** a taco stand and midnight pizza. **Weather:** rain and heat waves.
  - Tests: 30/30 new and 15/15 old.
  - **Stuck bug:** the map edge and the clouds pinned the bot for about 40 minutes in the Mayor chapter. Fixed with one solid boundary plus an unstick safety net. Also fixed: the vehicle leaking across save slots, and old saves losing upgrades after a price rescale.
- **v8 chase:** the user said "zombies are not chasing me… 0.75 my speed."
  - The cause: zombies ran in a straight line and got stuck on counters. Added **pathfinding** that re-plans twice a second, and a speed of 0.70–0.75× on foot.
  - The tests were written first and failed on the old build.

## Decisions (the user's words)
- **Not an ad clone**: "No, i am not looking to copy the add."
- **Testing is a requirement**: "tests should be made."
