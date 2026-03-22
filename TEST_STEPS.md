# Test Steps

This file is a running validation backlog and smoke-test reference. It should help manual testing, but it does not block development.

## Setup
1. Open a terminal in this repo root.
2. If `rojo` is not recognized, reopen VS Code or the terminal so the new PATH is picked up.
3. Start the Rojo server:
   ```powershell
   rojo serve
   ```
4. Open a place in Roblox Studio.
5. Make sure the Rojo Studio plugin is installed.
6. In the Rojo plugin, connect to the local Rojo server, usually `localhost:34872`.
7. Confirm [default.project.json](C:/Users/jeici/OneDrive/Documents/Roblox/default.project.json) syncs the repo into the DataModel.
8. In Studio, enable `Game Settings > Security > Enable Studio Access to API Services` if you want DataStore persistence during play tests.

## Mutation Chamber Loop
1. Join the game and spawn near the lab platform.
2. Walk to the chamber and press `E`.
3. Confirm the UI opens and shows `DNA Credits`, organism count, chamber state, and the specimen catalog.
4. In the catalog, load `Proto Slime`.
5. Confirm the chamber state changes from empty to loaded.
6. Press `Start Mutation`.
7. Confirm the timer counts down from about 10 seconds.
8. Wait for completion.
9. Confirm a popup appears with either a mutant result or a failure message.
10. Confirm `Proto Slime` stock drops by 1 when loaded into the chamber.
11. Confirm mutant storage count increases by 1 only on successful mutation.

## Research Exchange Loop
1. Produce at least one successful mutant.
2. Confirm the mutant appears in the Research Exchange list with a `Sell` button.
3. Sell the mutant.
4. Confirm the mutant disappears from storage.
5. Confirm `DNA Credits` increase by the mutant's rarity payout.
6. Confirm the sold count updates in the overview panel.

## Organism Unlock Loop
1. Earn at least `72` DNA Credits by selling mutants.
2. In the specimen catalog, confirm `Thorn Bud` shows an unlock action.
3. Unlock `Thorn Bud`.
4. Confirm DNA is deducted immediately.
5. Confirm the unlock grants starting stock for `Thorn Bud`.
6. Load `Thorn Bud` into the chamber.
7. Run several `Thorn Bud` mutations.
8. Confirm the results feel biased toward its configured trait profile compared with `Proto Slime`.

## Persistence Checks
1. Start a mutation and leave before the timer ends.
2. Rejoin with the same account.
3. Confirm the mutation either resumes with time remaining or resolves if its end time already passed.
4. Sell a mutant, rejoin again, and confirm the updated DNA balance persisted.
5. Unlock `Thorn Bud`, rejoin, and confirm the unlock state and its granted stock persisted.

## Edge Cases
1. Try starting a mutation with no loaded specimen and confirm the server rejects it.
2. Try loading another specimen while one is already loaded and confirm it is blocked.
3. Try loading while a mutation is already running and confirm the catalog shows the chamber as busy.
4. Use up all stock for an unlocked organism and confirm it can no longer be loaded.
5. Try selling the same mutant twice and confirm only the first sale succeeds.
6. Try unlocking `Thorn Bud` without enough DNA and confirm the unlock is blocked.
