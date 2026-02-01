# Why 5 Layout Templates?

## The Decision

Instead of allowing freeform card design, we offer exactly **5 pre-designed layout templates**:

1. **Title + Bullets** - For talking points
2. **Image + Notes** - For screenshots with context
3. **Two Images + Notes** - For comparisons
4. **2x2 Image Grid + Caption** - For multiple screenshots
5. **Full Image + 3 Bullets** - For hero images with key points

## Why Fixed Templates?

### 1. Speed of Creation

During a busy workday, sales engineers don't have time to design pretty cards. With templates:
- Choose a layout (2 seconds)
- Drop in content (30 seconds)
- Done

No fiddling with fonts, alignment, or spacing.

### 2. Consistent Readability

Templates are designed for **quick glancing during a presentation**:
- Optimal font sizes
- Clear hierarchy
- Generous spacing
- High contrast

If users designed their own layouts, many would be hard to read at a glance.

### 3. Simpler to Build

Freeform editing (like Canva) would require:
- Drag-and-drop positioning
- Resize handles
- Z-ordering (what's in front of what)
- Undo/redo
- Alignment guides
- And much more...

Templates let us deliver value faster.

### 4. Fits the Use Case

During a demo, you need to:
- Glance at notes quickly
- Get the key points
- Return focus to your demo

Complex, customized layouts would be overkill. Simple templates are actually *better* for this use case.

## Why These Specific 5?

We analyzed common presenter note patterns:

### Layout 1: Title + Bullets
**Use case**: Pure text talking points

Most common need. "When I'm on this part of the demo, remember to mention X, Y, Z."

```
┌─────────────────────┐
│ Key Points          │
├─────────────────────┤
│ • First thing       │
│ • Second thing      │
│ • Third thing       │
│ • Fourth thing      │
└─────────────────────┘
```

### Layout 2: Image + Notes
**Use case**: Screenshot with context

"Show this screen, and while showing it, say these things."

```
┌─────────────────────┐
│ ┌─────────────────┐ │
│ │     IMAGE       │ │
│ └─────────────────┘ │
├─────────────────────┤
│ Notes about the     │
│ image go here...    │
└─────────────────────┘
```

### Layout 3: Two Images + Notes
**Use case**: Before/after, comparison

"Show how it was, then how it is now."

```
┌─────────────────────┐
│ ┌───────┐ ┌───────┐ │
│ │ IMG 1 │ │ IMG 2 │ │
│ └───────┘ └───────┘ │
├─────────────────────┤
│ Notes about the     │
│ comparison...       │
└─────────────────────┘
```

### Layout 4: 2x2 Grid + Caption
**Use case**: Process flow, multiple screens

"Here's how the four steps work together."

```
┌─────────────────────┐
│ ┌───────┐ ┌───────┐ │
│ │ IMG 1 │ │ IMG 2 │ │
│ └───────┘ └───────┘ │
│ ┌───────┐ ┌───────┐ │
│ │ IMG 3 │ │ IMG 4 │ │
│ └───────┘ └───────┘ │
├─────────────────────┤
│ Caption text        │
└─────────────────────┘
```

### Layout 5: Full Image + 3 Bullets
**Use case**: Hero image with key takeaways

"This is the main screen. Call out these three things."

```
┌─────────────────────┐
│ ┌─────────────────┐ │
│ │                 │ │
│ │   LARGE IMAGE   │ │
│ │                 │ │
│ └─────────────────┘ │
├─────────────────────┤
│ • Key point one     │
│ • Key point two     │
│ • Key point three   │
└─────────────────────┘
```

## What We Considered Instead

### Freeform Canvas (Canva-style)

**Idea**: Let users place elements anywhere, resize freely, etc.

**Pros**: Maximum flexibility; users can create anything
**Cons**:
- Much harder to build
- Slower for users
- Results often look messy
- Overkill for quick presenter notes

**Why we didn't choose it**: The juice isn't worth the squeeze. Simple templates serve the use case better.

### More Templates (10+)

**Idea**: Offer many more layout options

**Pros**: More choices for users
**Cons**:
- Analysis paralysis (too many options)
- More development/maintenance work
- Diminishing returns

**Why we didn't choose it**: 5 covers the common cases. We can add more based on user feedback.

### Fewer Templates (1-2)

**Idea**: Just offer "text" and "text + image"

**Pros**: Extremely simple
**Cons**:
- Too limiting
- Common cases like comparison (two images) wouldn't be supported

**Why we didn't choose it**: We'd hear "can you add X layout" immediately.

### User-Created Templates

**Idea**: Let users design and save their own templates

**Pros**: Infinite customization
**Cons**:
- Complex to build
- Requires users to be designers
- Overhead of template management

**Why we didn't choose it**: MVP focus; could add later if users request it.

## Tradeoffs We Accept

### Limited Flexibility

If a user wants a layout we don't offer (e.g., 3 images in a row), they can't do it. They'd need to:
- Use a different layout
- Use multiple cards
- Request we add a new template

### One Size Doesn't Fit All

Our templates are optimized for typical screen sizes. On very small or very large overlays, some layouts might not look perfect.

### Future Maintenance

If we add more templates, each one needs:
- Editor view
- Renderer view
- Testing
- Documentation

We're intentionally starting small.

## Future Possibilities

Based on user feedback, we might add:
- Single large image (no text)
- Three-column layout
- Custom bullet counts
- User-defined templates

For now, these 5 templates cover the most common presenter note patterns.
