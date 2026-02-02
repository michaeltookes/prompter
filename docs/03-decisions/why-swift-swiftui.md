# Why Swift and SwiftUI?

## The Decision

We chose to build Prompter using **Swift** (Apple's programming language) and **SwiftUI** (Apple's modern user interface framework), with **AppKit** for advanced window features.

## What Are These Technologies?

### Swift
Swift is Apple's programming language for building Mac, iPhone, iPad, and other Apple platform apps. It replaced Objective-C as Apple's recommended language in 2014.

**In simple terms**: It's the "language" we use to write the app's logic.

### SwiftUI
SwiftUI is Apple's modern framework for building user interfaces. It was introduced in 2019 and focuses on describing *what* you want the interface to look like, rather than *how* to draw it step-by-step.

**In simple terms**: It's how we create the buttons, menus, and windows you see.

### AppKit
AppKit is Apple's older (but still powerful) framework for macOS apps. It gives us fine-grained control over windows and their behavior.

**In simple terms**: We use this for advanced features that SwiftUI doesn't handle, like making the overlay window float above everything.

## Why We Chose This Stack

### 1. Best Access to macOS Features

Our core feature (capture-protected overlay) requires deep integration with macOS. Only native code (Swift) gives us full access to:
- Window sharing types (`NSWindow.sharingType`)
- Global hotkey registration
- Floating window behavior
- Menu bar integration

JavaScript-based alternatives (like Electron) don't expose these APIs fully.

### 2. Performance

Prompter runs during live demos. It must:
- Start instantly
- Respond to hotkeys with zero lag
- Not consume noticeable CPU/memory
- Never slow down your demo

Native Swift apps are significantly faster and lighter than JavaScript-based alternatives.

**Comparison**:
| Metric | Swift/SwiftUI | Electron (JavaScript) |
|--------|---------------|----------------------|
| App size | ~5 MB | ~150+ MB |
| Memory usage | ~30 MB | ~200+ MB |
| Startup time | <1 second | 2-5 seconds |

### 3. Modern UI Development

SwiftUI makes building interfaces fast and maintainable:
- Declarative syntax (describe what you want)
- Automatic dark mode support
- Built-in animations
- Reactive updates (change data, UI updates automatically)

### 4. Future-Proof

Apple is investing heavily in SwiftUI. Using it means:
- We benefit from Apple's ongoing improvements
- New macOS features will be easily accessible
- The codebase stays modern

## What We Considered Instead

### Electron (JavaScript + Chromium)

**What it is**: A framework for building desktop apps using web technologies (HTML, CSS, JavaScript).

**Pros**:
- Easier to find developers
- Could share code with a potential web version
- Large ecosystem of libraries

**Cons**:
- Bundles a full web browser (huge app size)
- Limited access to native macOS features
- Performance overhead
- Window capture protection unclear

**Why we didn't choose it**: The core feature (capture protection) would be compromised or impossible.

### React Native for macOS

**What it is**: Facebook's framework for building native apps with JavaScript.

**Pros**:
- Familiar to React developers
- Closer to native than Electron

**Cons**:
- macOS support is less mature than iOS
- Still a translation layer between JavaScript and native
- Uncertain access to advanced window features

**Why we didn't choose it**: Risk of not being able to implement core features; macOS support is secondary for React Native.

### Pure AppKit (No SwiftUI)

**What it is**: Using only Apple's older UI framework.

**Pros**:
- Maximum control over every pixel
- Battle-tested, very stable

**Cons**:
- More verbose code
- Slower development
- Harder to maintain
- Missing modern conveniences

**Why we didn't choose it**: SwiftUI is productive enough for our UI needs, and we can drop into AppKit when necessary.

## The Hybrid Approach

We use both SwiftUI and AppKit:

| Layer | Technology | Why |
|-------|------------|-----|
| User interfaces (menus, editor, overlay content) | SwiftUI | Modern, fast to build, reactive |
| Window management (overlay behavior) | AppKit | Full control over window properties |
| System integration (hotkeys, menu bar) | AppKit | Required for these features |

SwiftUI and AppKit work together seamlessly - SwiftUI views can be hosted in AppKit windows.

## Tradeoffs We Accept

1. **Smaller developer pool**: Fewer people know Swift/SwiftUI than JavaScript
2. **macOS only**: This stack doesn't support Windows (but we chose macOS-only anyway)
3. **Learning curve**: SwiftUI is newer and still evolving
4. **AppKit complexity**: Some features require older, more complex APIs

These tradeoffs are acceptable because our core features require the capabilities only native code provides.
