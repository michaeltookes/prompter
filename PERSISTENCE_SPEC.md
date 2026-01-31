# Persistence Spec

## Filesystem Layout
~/Library/Application Support/PresenterOverlay/
- Decks/
  - <deckId>.json
- Assets/
  - <assetUuid>.<ext>
- Settings.json

## Save Behavior
- Auto-save deck on edit (debounced)
- Save on app background / quit
- Asset files copied immediately on import

## Loading
- On launch, load Settings.json
- Load last opened deck
- Restore overlay window position and size

