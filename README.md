# kazumi_minimal

Minimal Flutter demo that searches anime via XPath rules defined in JSON.

## Overview
- Loads rule config from `aowu.json`
- Builds search URL from keyword
- Fetches HTML with Dio and a Chrome User-Agent
- Parses items with `xpath_selector_html_parser`
- Displays results in a simple list UI
- Tap a result to print the resolved full URL

## Project Structure
- `lib/models/plugin_rule.dart` Rule model
- `lib/models/search_item.dart` Search item model
- `lib/services/anime_parser_service.dart` HTML fetch + XPath parse
- `lib/pages/search_page.dart` Search UI
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