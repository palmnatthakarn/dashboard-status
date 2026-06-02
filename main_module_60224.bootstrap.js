/* ENTRYPOINT_EXTENTION_MARKER */
// Disable require module timeout
require.config({
  waitSeconds: 0
});
// Create the main module loaded below.
define("main_module.bootstrap", ["web_entrypoint.dart", "dart_sdk"], function(app, dart_sdk) {
  dart_sdk.dart.setStartAsyncSynchronously(true);
  dart_sdk._debugger.registerDevtoolsFormatter();
  dart_sdk.dart.nativeNonNullAsserts(true);

  // See the generateMainModule doc comment.
  var child = {};
  child.main = app[Object.keys(app)[0]].main;

  /* MAIN_EXTENSION_MARKER */
  child.main();

  window.$dartLoader = {};
  window.$dartLoader.rootDirectories = ["http://localhost:60224"];
  if (window.$requireLoader) {
    window.$requireLoader.getModuleLibraries = dart_sdk.dart.getModuleLibraries;
  }
  if (window.$dartStackTraceUtility && !window.$dartStackTraceUtility.ready) {
    window.$dartStackTraceUtility.ready = true;
    let dart = dart_sdk.dart;
    window.$dartStackTraceUtility.setSourceMapProvider(function(url) {
      var baseUrl = window.location.protocol + '//' + window.location.host;
      url = url.replace(baseUrl + '/', '');
      if (url == 'dart_sdk.js') {
        return dart.getSourceMap('dart_sdk');
      }
      url = url.replace(".lib.js", "");
      return dart.getSourceMap(url);
    });
  }
  // Prevent DDC's requireJS to interfere with modern bundling.
  if (typeof define === 'function' && define.amd) {
    // Preserve a copy just in case...
    define._amd = define.amd;
    delete define.amd;
  }
});
