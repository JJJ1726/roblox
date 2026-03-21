# Test Steps

## Setup
1. Open the project in Roblox Studio using Rojo or copy the scripts into a place manually.
2. Make sure `default.project.json` syncs into the DataModel.
3. In Studio, enable `Game Settings > Security > Enable Studio Access to API Services` if you want DataStore persistence during play tests.

## Functional Test
1. Join the game and spawn near the lab platform.
2. Walk to the chamber and press `E`.
3. Confirm the UI opens and shows `Proto Slime` inventory plus `DNA Credits`.
4. Press `Insert Proto Slime`.
5. Confirm the chamber state changes from empty to loaded.
6. Press `Start Mutation`.
7. Confirm the timer counts down from about 10 seconds.
8. Wait for completion.
9. Confirm a popup appears with either a mutant result or a failure message.
10. Confirm base inventory is reduced by 1.
11. Confirm mutant storage count increases by 1 only on successful mutation.
12. If the mutation succeeds, press `Sell` on the stored mutant.
13. Confirm the mutant is removed and `DNA Credits` increase by the rarity-based payout.

## Persistence Test
1. Insert a specimen and start a mutation.
2. Leave before the timer ends.
3. Rejoin with the same account.
4. Confirm the mutation either resumes with time remaining or resolves if its end time already passed.
5. Sell a stored mutant.
6. Rejoin again and confirm both the mutant removal and `DNA Credits` balance were saved.

## Edge Cases
1. Try starting a mutation with no inserted specimen and confirm the server rejects it.
2. Try inserting while a mutation is already running and confirm the server rejects it.
3. Use up all starter specimens and confirm insertion is blocked at zero inventory.
4. Try selling the same mutant twice and confirm only the first sale succeeds.
