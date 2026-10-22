# Verification record

## Environment

- Windows 11 host.
- Flutter **3.44.8**, Dart **3.12.2**, pinned through mise in `.mise.toml`.
- `flutter_riverpod` **3.4.3**; legacy `provider` dependency removed.
- Chrome **155** used for the production-web smoke check.
- `mise doctor`: no problems; only an optional mise update notice.

## Actual results

| Check | Result |
| --- | --- |
| Dart formatting | `dart format` applied; final format check clean |
| Static analysis | `flutter analyze`: no issues |
| Automated tests | `flutter test`: **44 passed** |
| Release web compilation | `flutter build web`: succeeded |
| Live API integration | `dart run tool/verify_live_api.dart`: 30 real Pokémon, all with type data |
| Production browser run | Built release opened in headless Chrome against real PokéAPI; displayed `30 of 30 Pokémon` |
| Visual review | Desktop 1280×1000 and phone 390×844 screenshots captured and inspected |

The live dataset returned Bulbasaur through Nidorina and nine available types:
Bug, Electric, Fire, Flying, Grass, Ground, Normal, Poison, Water.

Screenshots: [desktop](images/desktop.png), [phone](images/mobile.png).
These show real API records/artwork, not a mock UI.

## Automated coverage

### API and model

- Original list endpoint and 30-result cap.
- Type data from actual detail response fields, not inferred from IDs.
- Secondary types, dimensions, stats, image URL and name formatting.
- Six-request concurrency bound, stable list order, immutable returned values.
- Empty responses; list/detail HTTP errors; connection errors and timeouts.
- Malformed JSON, missing/invalid types, mismatched IDs, duplicate IDs, invalid stats.

### Riverpod state

- Automatic initial fetch and initial/loading/success transitions.
- One in-flight Future shared by concurrent refresh calls; later refresh fetches again.
- Add/remove favorite, unknown ID guard, panel toggle.
- Add/edit/trim/remove nickname, blank/length validation, original name retained.
- Actual primary/secondary type filtering and clearing.
- Favorites independent of active filter.
- Personalizations and panel/filter state preserved through successful refresh.
- Edits performed during a pending fetch preserved at completion.
- Initial errors and retry recovery; failed refresh retains prior data.
- Generic error fallback without exposing raw exception details.
- Empty API result vs. zero filter matches.
- Immutable snapshots and no ghost favorite cards for missing records.
- Disposal closes the service; late completion does not write disposed state.
- A fresh app scope does not retain session-only personalizations.

### Flutter widgets

- Loading/error/retry/empty screens and broken-image fallback.
- Real reactive heart state, favorites count, panel expansion/collapse.
- Nickname add/edit/cancel/remove and validation across card/detail/favorites views.
- Type filter, secondary-type match, clear action, independent favorites panel.
- Both refresh controls call the existing fetch method and retain personalizations.
- Failed-refresh banner and still-usable previous data.
- Empty filter recovery.
- Favorites reachable on detail pages; immediate removal.
- Opening a second favorite and navigating back restores the correct route's Pokémon.
- Phone, short landscape, and desktop viewport layouts.
- 200% text-scale phone layout. Testing exposed an app-bar overflow; the responsive
  icon-only favorite control and adaptive toolbar height fixed it before completion.

## Reproduce

```sh
mise install
mise exec -- flutter pub get
mise exec -- dart format --output=none --set-exit-if-changed lib test tool
mise exec -- flutter analyze
mise exec -- flutter test
mise exec -- flutter build web
mise exec -- dart run tool/verify_live_api.dart
```

On Windows use `mise exec -- cmd /c ...` if required to invoke batch commands.
The live integration command needs internet. Unit/widget tests inject dependencies
and mock HTTP; they do not depend on network availability.

## Limits — not claimed as verified

- No Android SDK is installed on this host, so no Android APK/emulator/device run
  was performed. The project retains Android scaffolding and internet permission.
- No Windows C++ toolchain is installed, so a Windows-native executable was not built.
- iOS/macOS builds require an appropriate macOS toolchain and were not run here.
- Automated interaction coverage is in Flutter widget tests. The live Chrome
  smoke check verifies release rendering/data loading and screenshots, not a
  separate end-to-end run of every gesture.
- Nicknames/favorites are in-memory Riverpod state, not restart-persistent storage.
- Preserving previously loaded data on a refresh failure is not persistent offline caching.
- A successful build/tests do not guarantee a grade; the student must understand
  the implementation and meet the instructor's submission/video requirements.
