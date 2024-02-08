---
date: 20230515
---

# Notes about "flutter assemble"

`flutter assemble` provides a low level API to interact with the flutter tool
build system. It was implemented in [PR #32816].

Example invocation that generates `flutter_assets` directory and `arm64-v8`
directory containing `app.so`:

```bash
flutter assemble android_aot_bundle_release_android-arm64 \
	--define BuildMode=release \
	--define TargetPlatform=android-arm64 \
	--output ~/Desktop
```

Invocation that generates `flutter_assets` with debug contents:

```bash
flutter assemble debug_android_application \
	--define BuildMode=debug \
	--define TargetPlatform=android-arm64 \
	--output ~/Desktop
```

Invocation spied from running `./gradlew :app:assembleDebug --info`:

```bash
/home/bartek/flutter/bin/flutter --quiet assemble \
	--no-version-check \
	--depfile /home/bartek/dev/discover_rudy/build/app/intermediates/flutter/debug/flutter_build.d \
	--output /home/bartek/dev/discover_rudy/build/app/intermediates/flutter/debug \
	-dTargetFile=lib/main.dart \
	-dTargetPlatform=android \
	-dBuildMode=debug \
	-dTrackWidgetCreation=true \
	debug_android_application
```

`flutter assemble` is called by the Flutter Gradle Plugin, [here][location].

[PR #32816]: https://github.com/flutter/flutter/pull/32816
[location]: https://github.com/flutter/flutter/blob/3.16.0/packages/flutter_tools/gradle/src/main/groovy/flutter.groovy#L1350-L1411
