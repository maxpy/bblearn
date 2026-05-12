{{flutter_js}}
{{flutter_build_config}}

// Load CanvasKit from Google CDN (not bundled) to reduce initial download size.
// The engine revision is embedded in _flutter.buildConfig at build time.
const engineRevision = _flutter.buildConfig?.engineRevision;
const canvasKitBase = engineRevision
  ? `https://www.gstatic.com/flutter-canvaskit/${engineRevision}/`
  : "canvaskit/";

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: canvasKitBase,
  },
});
