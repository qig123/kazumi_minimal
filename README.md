# kazumi_minimal

Minimal Flutter demo that searches anime via XPath rules defined in JSON and can sniff the real video stream URL using a headless WebView (Kazumi style).

## Overview
- Loads rule config from `aowu.json`
- Builds search URL from keyword
- Fetches HTML with Dio and a Chrome User-Agent
- Parses items with `xpath_selector_html_parser`
- Displays results in a simple list UI
- Tap a result to sniff the direct video URL via headless WebView

## Core Sniffing Flow (Kazumi Style)
- Create `HeadlessWebview` (webview_windows)
- `run()` the headless instance
- Listen to:
  - `onM3USourceLoaded`
  - `onVideoSourceLoaded`
- `loadUrl(episodeUrl)`
- First match wins, print URL and redirect to `about:blank`
- Timeout if nothing is detected

### Runtime Notes
- WebView2 Runtime is required on Windows. The sniffer checks `HeadlessWebview.getWebViewVersion()` and throws if missing.
- `webview_windows` does not provide direct request headers in `loadUrl`, so Referer is simulated by loading the origin first and then setting `window.location.href` to the play page.

## Project Structure
- `lib/models/plugin_rule.dart` Rule model
- `lib/models/search_item.dart` Search item model
- `lib/services/anime_parser_service.dart` HTML fetch + XPath parse
- `lib/services/video_sniffer_service.dart` Headless WebView sniffer
- `lib/pages/search_page.dart` Search UI + sniff dialog
- `aowu.json` Example rule file (also registered as an asset)

## Run
1. `flutter pub get`
2. `flutter run`

## Rule Format
Required fields used by the demo:
- `name`
- `baseURL`
- `searchURL` (use `@keyword` placeholder)
- `searchList` (XPath for item containers)
- `searchName` (XPath for item title)
- `searchResult` (XPath for item link)

## Notes
- `aowu.json` is loaded from assets via `rootBundle`, so keep it listed under `flutter.assets` in `pubspec.yaml`.