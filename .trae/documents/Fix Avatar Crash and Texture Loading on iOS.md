## Crash Analysis
- The stack shows `Error._throw` from a microtask, which indicates an uncaught async exception during the avatar’s WebView/model-viewer initialization.
- Likely triggers: eager WKWebView init, heavy JS event listeners modifying camera orbit, or invalid/missing texture paths causing `model-viewer` errors that bubble via microtasks on iOS.
- Secondary contributors: repeated WebView teardown/re-init when navigating (no keep-alive), heavy GLB textures, and aggressive `reveal`/environment settings.

## Objectives
1. Stop crashes and freezes during avatar load on iOS.
2. Ensure textured avatar renders reliably (no plain white mesh).
3. Reduce loading latency and avoid repeated initialization.
4. Add robust logging and fallback behavior.

## Implementation Plan
### 1) Harden Initialization and Lifecycle
- Add `AutomaticKeepAliveClientMixin` and `bool get wantKeepAlive => true` in `Avatar3DWidget` to keep the WebView alive across navigations.
- Defer first render by ~600–800 ms after first frame (`WidgetsBinding.instance.addPostFrameCallback` + `Future.delayed`) to avoid early WKWebView init edge cases.
- Switch `ModelViewer.loading` to `Loading.lazy` and keep `poster` to show an immediate image while the 3D model loads.

### 2) Remove Crash-Prone Runtime Hooks
- Remove/trim `relatedJs` listeners that manipulate camera orbit or intercept `dblclick` during load; enforce camera constraints via `ModelViewer` props (`minCameraOrbit`, `maxCameraOrbit`, `disableZoom`, fixed `fieldOfView`).
- Keep minimal `relatedCss` only (transparent poster/fit sizing).
- Avoid `environmentImage` and `reveal` settings during initial load on iOS to reduce init pressure.

### 3) Asset Correctness and Fallbacks
- Ensure `pubspec.yaml` declares `assets/avatars/3d/` and `assets/avatars/2d/` directories.
- Default `full3DPath` to a known textured GLB (e.g., `scene_with_textures.glb`) for all avatars until specific models exist.
- Prewarm GLB/poster via `rootBundle.load` (best effort) before rendering.
- Add a timeout (2–3s). If load not completed or an error is detected, set `_hasError=true` and render the 2D fallback immediately.

### 4) Logging and Diagnostics
- Add detailed logs around init, asset prewarm, and `ModelViewer` creation (use `Stopwatch` to time load stages).
- Confirm global error hooks are present: `FlutterError.onError` and `PlatformDispatcher.instance.onError` to capture the preceding error message before `Error._throw`.

### 5) iOS-Specific Stability
- Remove any `dependency_overrides` that pins `webview_flutter_wkwebview` to outdated versions; let `pub` resolve compatible transitive versions.
- Keep Pods and Xcode configs aligned (already done), and avoid heavy WebView JS during load.

### 6) Performance Optimizations
- Maintain WebView via keep-alive to prevent repeated heavy init.
- Consider using a lighter GLB and compressed textures (KTX2) for large avatars; ensure textures are embedded or paths are relative and valid.

## Code Changes (Files & Edits)
- `lib/widgets/avatar_3d_widget.dart`:
  - Add `AutomaticKeepAliveClientMixin` + `wantKeepAlive` getter.
  - Defer `_shouldLoadModel = true` by ~600–800 ms after the first frame.
  - Use `poster` and `Loading.lazy`; remove `relatedJs`, keep minimal `relatedCss`.
  - Enforce camera constraints via props: fixed `cameraOrbit`, `min/maxCameraOrbit`, `disableZoom`, fixed `fieldOfView`.
  - Prewarm assets with `rootBundle.load` and implement timeout-based fallback.
- `lib/models/avatar.dart`:
  - Point all avatars’ `full3DPath` to a known textured GLB; use a common 2D poster.
- `pubspec.yaml`:
  - Ensure `assets/avatars/3d/` and `assets/avatars/2d/` directories are declared.
  - Remove legacy override for `webview_flutter_wkwebview`.

## Testing
- iPhone 17 Pro simulator (iOS 26): run debug and profile; verify no crash-on-load, poster appears immediately, textured model loads.
- Measure load time and frame budget via performance overlay and DevTools.
- Navigate away and back to confirm keep-alive prevents re-init latency.
- Optional: iPad simulator for large display behavior.

## Acceptance Criteria
- No microtask crash or app pause during avatar load.
- Avatar renders with proper textures; no plain white mesh.
- Loading latency reduced; poster visible within ~100 ms, model within a few seconds.
- Logs contain clear lifecycle and error messages.

## Rollback/Safety
- If 3D still crashes on iOS, gate behind an env flag (`ENABLE_3D_AVATAR=false`) to show 2D fallback while we iterate.

## Deliverables
- Code changes as above.
- A short test report: load timings, memory observations, and confirmation of no runtime exceptions.
