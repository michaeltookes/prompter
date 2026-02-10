# Project Structure

Prompter/
│
├── App/
│   ├── PrompterApp.swift
│   ├── AppState.swift
│   ├── MenuBarController.swift
│
├── Windows/
│   ├── DeckEditorWindow.swift
│   ├── OverlayWindowController.swift
│   ├── TestCaptureWindow.swift
│
├── Views/
│   ├── DeckEditor/
│   │   ├── DeckEditorView.swift
│   │   ├── CardListSidebar.swift
│   │   ├── CardCanvasView.swift
│   │   └── LayoutViews/
│   │       ├── TitleNotesLayoutView.swift
│   │       ├── ImageTopNotesLayoutView.swift
│   │       ├── TwoImagesNotesLayoutView.swift
│   │       ├── Grid2x2CaptionLayoutView.swift
│   │       └── FullBleedImageBulletsLayoutView.swift
│   │
│   ├── Overlay/
│   │   ├── OverlayView.swift
│   │   ├── OverlayCardRenderer.swift
│   │
│   ├── Shared/
│   │   ├── ImageDropZone.swift
│   │   ├── FrostedPanel.swift
│   │   └── IconButton.swift
│
├── Models/
│   ├── Deck.swift
│   ├── Card.swift
│   ├── LayoutType.swift
│   ├── AssetRef.swift
│   └── Settings.swift
│
├── Services/
│   ├── PersistenceService.swift
│   ├── AssetManager.swift
│   ├── HotkeyManager.swift
│   └── OverlayManager.swift
│
└── Resources/
    ├── Assets.xcassets
    └── AppIcons

