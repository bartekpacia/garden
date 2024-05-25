---
date: 20231125
---

# Flutter Engine notes

This is a quick-start guide of setting up the Flutter engine development
environment, making a simple change, and using it in a Flutter app.

My setup is fairly standard – I'm on M1 Mac, Android emulator is arm64, iOS
simulator is arm64 as well. No Rosetta2 involved.

# Prepare

This step is well explained by [the official guide].

First step is to clone [depot_tools] into $HOME:

```
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ~/depot_tools
```

Since I don't do Engine development often, I don't want `depot_tools` in my
$PATH by default. Instead, I export it only when I need it:

```
export PATH="$HOME/depot_tools:$PATH"
```

# Build

### Build host-side executables

Generate build files:

```
./flutter/tools/gn --unoptimized --mac-cpu arm64
```

Run build:

```
ninja -C out/host_debug_unopt_arm64
```

### Build for Android emulator

Generate build files:

```
./flutter/tools/gn --android --android-cpu arm64 --unoptimized
```

Run build:

```
ninja -C out/android_debug_unopt_arm64
```

To build only the JAR (skipping things like generating javadoc, linting):

```
ninja -C out/android_debug_unopt_arm64 android_jar
```

### Build for iOS simulator

Generate build files:

```
./flutter/tools/gn --ios --unoptimized --simulator --simulator-cpu arm64
```

Run build:

```
ninja -C out/ios_debug_sim_unopt_arm64
```

# Run

Let's assume that:

```
export FLUTTER_ENGINE=~/dev/bartekpacia/engine/src/
```

Android emulator ARM64:

```bash
flutter \
	--local-engine android_debug_unopt_arm64 \
	--local-engine-host host_debug_unopt_arm64 \
	--local-engine-src-path "$FLUTTER_ENGINE" \
	run
```

iOS simulator ARM64 (only the `--local-engine` argument differs):

```bash
flutter \
	--local-engine ios_debug_sim_unopt_arm64 \
	--local-engine-host host_debug_unopt_arm64 \
	--local-engine-src-path "$FLUTTER_ENGINE" \
	run
```

Theoretically, passing `--local-engine-src-path $FLUTTER_ENGINE` is redundant -
the default value is `$FLUTTER_ENGINE`. For example you could set:

```
export FLUTTER_ENGINE=~/dev/bartekpacia/engine/src
```

Unfortunately I've found it to be a bit flaky, and prefer to pass
`--local-engine-src-path` explicitly and not set `$FLUTTER_ENGINE` envvar.

# Test

Run Android tests of `AccessibilityBridge` with Roboelectric:

```bash
./testing/run_tests.py \
	--type java \
	--variant host_debug_unopt_arm64 \
	--android android_debug_unopt_arm64 \
	--java-filter io.flutter.view.AccessibilityBridge
```

[the official guide]: https://github.com/flutter/flutter/blob/master/docs/engine/dev/Setting-up-the-Engine-development-environment.md
[depot_tools]: https://chromium.googlesource.com/chromium/tools/depot_tools
