# Data Model

## Deck
- id: UUID
- title: String
- createdAt: Date
- updatedAt: Date
- cards: [Card]
- currentCardIndex: Int (for overlay state)

## Card
- id: UUID
- layout: LayoutType (enum)
- title: String? (layout dependent)
- notes: String? (layout dependent)
- bullets: [String]? (layout dependent)
- caption: String? (layout dependent)
- imageSlots: [AssetRef?] (length depends on layout)
- createdAt: Date
- updatedAt: Date

## LayoutType enum
- TITLE_BULLETS
- IMAGE_TOP_NOTES
- TWO_IMAGES_NOTES
- GRID_2X2_CAPTION
- FULL_BLEED_IMAGE_3_BULLETS

## AssetRef
- id: UUID
- filename: String
- originalName: String?
- createdAt: Date

## Settings
- overlayOpacity: Double
- overlayFontScale: Double
- overlayFrame: {x,y,w,h}
- clickThroughEnabled: Bool
- protectedModeEnabled: Bool
- lastOpenedDeckId: UUID?
- timerEnabled: Bool
- timerMode: String ("deck" | "perCard")
- timerTotalSeconds: Int
- timerPerCardSeconds: Int
- timerShowPauseButton: Bool
- timerApplyMode: String ("all" | "selected")
- timerSelectedDeckIds: [UUID]
