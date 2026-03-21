# Mutation Lab: Grow Anything

## Vision
Mutation Lab is a session-friendly Roblox experience where players feed simple organisms into experimental chambers, wait through a short mutation cycle, and collect bizarre creations with different rarity and trait rolls.

This repository currently implements three completed slices:
- Slice 1: a playable Mutation Chamber loop
- Slice 2: a Research Exchange loop that converts mutants into soft currency
- Slice 3: an organism unlock loop that uses soft currency to expand the specimen catalog

## Player Fantasy
- I run a sketchy biotech lab.
- I insert something small and ordinary.
- I push my luck with a mutation.
- I wait through a suspense timer.
- I either get a collectible mutant or a failed sludge result.

## Core Loop For Slice 1
1. Walk to the chamber and open the chamber UI.
2. Insert a base organism from inventory.
3. Start a mutation cycle.
4. Wait for the timer to finish.
5. Receive the mutation result in a popup and in persistent storage.
6. Repeat to build a collection.

## Current Content
- Base organism:
  - `Proto Slime`
  - `Thorn Bud` after unlock
- Mutation outcome structure:
  - weighted rarity roll
  - weighted trait roll
  - chance to fail
- Mutation duration:
  - 10 seconds
- Research economy:
  - sell completed mutants for `DNA Credits`
  - rarity-based sell values
  - persistent currency balance
- Progression unlock:
  - spend `DNA Credits` to unlock `Thorn Bud`
  - unlock grants starting stock for the new organism
  - organism-specific trait bias changes mutation flavor

## Retention Priorities
- Short interaction loop with immediate replay potential
- Persistent mutant collection
- Visible chamber state so players know what to do next
- Simple reward sink and payout language so progress feels measurable early
- Room for daily rewards, quests, and chained crafting later

## Monetization Priorities For Future Slices
- Premium mutation accelerators
- Extra chamber slots
- Cosmetic lab skins
- Limited event trait pools

These are intentionally not implemented yet. The first slice stays focused on one clean, replayable system.
