# Jewte design direction

Layout reference: TypeUI's publicly available **Application Shell With Toolbar** prompt, copied using the page's free Copy prompt button on https://www.typeui.sh/prompts/shells. Its consistent shell, separate navigation/content regions, comfortable content padding, responsive hierarchy and visible primary actions informed this native mobile interpretation. No paid or locked prompt was accessed.

The mobile interpretation uses a stable top identity/search/settings region, a four-destination bottom navigation bar, and separate subject/filter/content regions. Wider windows use a side rail. Topic details open as a scrollable bottom sheet so the study context stays underneath.

## Visual tokens

| Role | Value |
| --- | --- |
| Paper background | `#F6F5EF` |
| Carbon text | `#202D25` |
| Forest primary | `#294C3D` |
| Chartreuse accent | `#D4EC85` |
| Muted text | `#667267` |
| Dark background | `#171E19` |
| Dark surface | `#222C24` |

Manrope is bundled for interface typography; DM Serif Display is bundled for the opening heading. Their SIL Open Font License texts are included in assets/fonts. The Jewte logo is an authored geometric open book with a check mark, drawn in Flutter Canvas and Android vector resources, with raster fallbacks for older launchers. Icons use Flutter's bundled Material Icons. The orbit decoration is drawn directly with Flutter Canvas.

Motion uses one restrained 180 ms tab fade, 160 ms checkbox feedback and 240–300 ms progress transitions. Each tab has its own scroll controller and retains its position. Inactive tabs pause their tickers; long niche and saved collections render lazily. Appearance preferences alone rebuild the MaterialApp theme. Reduce Motion in Settings and the Android accessibility setting suppress custom animations. No gradients, external image downloads, stock illustrations, timers, daily streaks or deadline targets are used.

Niche topics are curated source-backed question patterns, not frequency claims or predictions. They reference the same canonical topic records used by the subject checklist. Cross-subject aliases route to a single owner and a single completion record.

## Home-screen widgets

Two resizable native RemoteViews widgets use the same forest/chartreuse palette: progress (opens Subjects) and next concept (opens its detail or an exact-topic YouTube search). The gallery renders previews from the actual native layouts on Android. A compact mirror is synchronized only after the canonical Flutter progress repository succeeds, with serialized native writes. Widgets are display-only; checklist edits remain in the app. No timer, network refresh, streak or deadline is added. Widget pinning uses the launcher’s confirmation UI.
