# Settings, edge media and motion

Settings now group controls into ten searchable categories and load pages on
demand. Widget previews, material choices, wallpaper comparisons and finite
motion previews keep related adjustments together. Settings share the bar's
material and form a continuous surface with the bottom frame. Configuration
continues through the existing controllers and persistence services.

The right edge contains Spotify, Discord and WhatsApp icons. Spotify opens a
full-height media panel; Discord and WhatsApp are visual placeholders. During
Spotify playback, hovering its icon exposes Lyrics. Media contours consume the
shared audio analyzer; Lyrics contours follow verse timestamps. Lyrics use the
bundled Liberation Serif font, glow on the active verse and smooth scrolling.
Dragging the lyrics pauses following until it is resumed.

Opening edge media morphs the bottom visualizer into the left rail over 2.2
seconds. Closing starts the reverse movement, fades content for 180 ms and
retracts the surface over 760 ms while retaining its height and last contour.
Repeated closing requests do not restart the exit; reopening reverses it.
Volume and brightness feedback preserve the media panel.

Topbar and sidebar glyphs share the right-edge hover motion without moving their
input areas. Volume and brightness use the same geometry/content sequence and
handoff as the other sidebar panels. Reduced motion bypasses these transitions.

The sidebar media card is temporarily disabled. Existing media services and
transport functions remain available. Settings, power profiles and monitor
controls retain their backend operations, including monitor rollback.

The test suite is included in the repository; see [validation](../tests/README.md).
Compositor visual approval, tests and measured performance are distinct: no
performance improvement percentage is claimed. Physical multi-monitor coverage
and a new controlled performance comparison remain outside this release check.
