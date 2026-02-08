# kazumi_minimal

Minimal Flutter desktop demo that searches anime via XPath rules and plays the real stream URL sniffed from a headless WebView (Kazumi style, Windows-only).

## Overview
- Loads rules from KazumiRules (GitHub raw, manual refresh, cached locally)
- Builds search URL from keyword
- Fetches HTML with Dio and a Chrome User-Agent
- Parses items with `xpath_selector_html_parser`
- Shows results list
- Tap a result to open detail page (episodes + routes)
- Tap an episode to sniff the direct video URL
- Auto-navigate to `media_kit` player and play full-screen

## End-to-End Flow
1. User enters a title
2. Search returns items
3. Tap an item �� parse detail page episodes
4. Select route + episode �� build play page URL
5. Headless WebView sniffs `.m3u8` / `video/mp4`
6. Direct URL is passed to `media_kit` and played

## Rule Management
- Source: `https://raw.githubusercontent.com/Predidit/KazumiRules/master/index.json`
- Manual refresh from the Rule picker page (only time remote fetch happens)
- Outdated rules are hidden by default (toggle to show)
- Cached locally in `%APPDATA%\kazumi_minimal\rules_cache.json`
- On startup, only cache is read; if empty, no rules are shown until refresh.
- Refresh downloads index and rule files into local cache.

## Core Sniffing Flow (Kazumi Style)
- Create `HeadlessWebview` (webview_windows)
- `run()` the headless instance
- Listen to:
  - `onM3USourceLoaded`
  - `onVideoSourceLoaded`
- `loadUrl(episodeUrl)`
- First match wins, print URL and redirect to `about:blank`
- Timeout if nothing is detected

## Episode Parsing (Kazumi Style)
- `parseChapters(rule, detailUrl)`
- GET detail page via Dio
- XPath `chapterRoads` �� per-road nodes
- XPath `chapterResult` �� episode links
- Build `EpisodeItem(title, url, roadIndex)` and filter empty values
- Group by `roadIndex` for route tabs

### Runtime Notes
- WebView2 Runtime is required on Windows. The sniffer checks `HeadlessWebview.getWebViewVersion()` and throws if missing.
- `webview_windows` does not provide direct request headers in `loadUrl`, so Referer is simulated by loading the origin first and then setting `window.location.href` to the play page.

## Project Structure
- `lib/models/plugin_rule.dart` Rule model
- `lib/models/search_item.dart` Search item model
- `lib/models/episode_item.dart` Episode model
- `lib/models/rule_info.dart` Rule index model
- `lib/services/anime_parser_service.dart` HTML fetch + XPath parse
- `lib/services/video_sniffer_service.dart` Headless WebView sniffer
- `lib/services/rule_repository.dart` Rule loader + cache
- `lib/pages/search_page.dart` Search UI
- `lib/pages/rule_picker_page.dart` Rule picker UI
- `lib/pages/episode_page.dart` Routes + episodes UI
- `lib/pages/simple_player_page.dart` media_kit full-screen player

## Run
1. `flutter pub get`
2. `flutter run -d windows`

## Rule Format
Required fields used by the demo:
- `name`
- `baseURL`
- `searchURL` (use `@keyword` placeholder)
- `searchList` (XPath for item containers)
- `searchName` (XPath for item title)
- `searchResult` (XPath for item link)
- `chapterRoads` (XPath for route blocks)
- `chapterResult` (XPath for episode links)

Optional fields:
- `userAgent`
- `referer`

## TODO
- Consider randomized User-Agent (Kazumi-style) if specific sources fail to play.

## Notes
- _resolveWithProvider拿到source
