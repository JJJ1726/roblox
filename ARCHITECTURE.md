# Architecture

## Project Layout
- `src/ReplicatedStorage/Shared`
  - shared config and pure mutation roll logic
- `src/ServerScriptService`
  - bootstrap script and server-only services
- `src/StarterPlayer/StarterPlayerScripts/Controllers`
  - client UI/controller logic

## Service Boundaries
### Shared
- `MutationConfig`
  - canonical data for base organisms, rarity tiers, trait weights, and chamber timing
- `MutationRoller`
  - pure weighted RNG mutation logic
  - deterministic when provided the same seed

### Server
- `DataService`
  - loads and saves player data
  - autosaves and handles shutdown flush
- `InventoryService`
  - owns player inventory, chamber inventory, and resolved mutation storage
  - produces sanitized client state snapshots
- `MutationChamberService`
  - creates remotes
  - creates the chamber world object if missing
  - validates chamber actions
  - schedules mutation completion

### Client
- `MutationChamberController`
  - builds a simple screen UI at runtime
  - invokes server remotes
  - renders timer/state updates
  - shows result popup

## Networking
- `RemoteFunction GetState`
  - returns full client-safe chamber state
- `RemoteFunction InsertBaseOrganism`
  - inserts a selected base specimen into the chamber
- `RemoteFunction StartMutation`
  - starts the active mutation timer
- `RemoteEvent OpenChamber`
  - opens the UI when the proximity prompt is used
- `RemoteEvent StateUpdated`
  - pushes fresh server state to the player
- `RemoteEvent MutationResolved`
  - pushes the final result immediately on completion

## Persistence Model
Player data stores:
- base organism inventory
- mutant inventory
- chamber inserted specimen
- active mutation payload
- simple mutation stats
- most recent resolved mutation

Persisting the chamber payload allows a mutation to resume or resolve after a reconnect instead of silently disappearing.

## Scaling Notes
- Chamber logic is per-player right now even though the scene object is shared.
- Mutation rolls are data-driven so new organisms, rarity tiers, or event pools can be added without rewriting the loop.
- Inventory output currently stores full mutant records in one list. If the game scales hard, this should move to stacked variants, pagination, or archive buckets.

