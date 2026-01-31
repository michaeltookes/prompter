# Image Handling

## User Actions
- Drag & drop images into card slots
- Paste image from clipboard into selected slot
- Replace/remove image per slot

## Storage
All images are copied into:
~/Library/Application Support/PresenterOverlay/Assets/

Rename each file to UUID:
<uuid>.png (or preserve extension)

Cards reference images via AssetRef:
- id (uuid)
- filename
- createdAt
- originalName (optional)

## Rendering
- Use NSImage for decode
- Cache thumbnails and scaled variants
- Avoid re-decoding on every overlay update
- Provide placeholder UI when slot is empty: "Drop Image"

## Performance
- Generate thumbnails on import
- Keep originals for quality but render scaled in overlay

