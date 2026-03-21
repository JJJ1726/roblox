# Mutation Lab: Grow Anything

## Vision
Mutation Lab is a session-friendly Roblox experience where players feed simple organisms into experimental chambers, wait through a short mutation cycle, and collect bizarre creations with different rarity and trait rolls.

This repository only implements the first vertical slice:
- one playable Mutation Chamber loop
- one starter base organism
- weighted RNG mutation results
- a failure state
- persistence for inventory, chamber state, and created mutants

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
- Mutation outcome structure:
  - weighted rarity roll
  - weighted trait roll
  - chance to fail
- Mutation duration:
  - 10 seconds

## Retention Priorities
- Short interaction loop with immediate replay potential
- Persistent mutant collection
- Visible chamber state so players know what to do next
- Room for daily rewards, quests, and chained crafting later

## Monetization Priorities For Future Slices
- Premium mutation accelerators
- Extra chamber slots
- Cosmetic lab skins
- Limited event trait pools

These are intentionally not implemented yet. The first slice stays focused on one clean, replayable system.

