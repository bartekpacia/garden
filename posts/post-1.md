---
date: 20220527
---

# Suckless Android SDK setup

Android SDK is one of the first things I set up on a new computer. This post is
a reference for future me and for anyone who wants to do it right and learn
something along the way.

This post is for you if you:

- need Android SDK, but don't want to install the bulky Android Studio
- want to know more about what Android SDK provides and have a rough idea of its
  structure

## Preface and rant

Why am I writing this post? Surely there are official guides on installing
Android SDK?

Well, I think that the official, recommended way of downloading Android SDK
sucks. More specifically, telling everyone to install Android Studio sucks.

I'm under the impression that the official docs are optimized for the lowest
common denominator type of person. That's not a bad thing when you're just
getting started with Android development, but after doing the setup of SDK a few
times, I want to know more about what I am doing and why I am doing it. And
that's what the official docs fall short of.

Another problems appears when building on CI. The more popular ones have some
kind of pre-built "Set up Android SDK" step, but it's not always the case. And
you won't install Android Studio on a CI server, right. Right?

I also strongly believe that everyone should know a thing or two about the tools
they're depending on every day.

## Basics

### Install Java Development Kit

I use the [Eclipse Temurin] JDK distribution, but other ones should work too. On
macOS (which I use), installing them is as simple as:

```
brew tap homebrew/cask-version
brew install temurin17
```

> Unless you're spelunking in some legacy project, you should use JDK 17, since
> it's the latest LTS release.

Then, set `JAVA_HOME` and add the binaries to `PATH`. To do it, open your
`~/.bashrc`, `~/.zshrc`, or whateverrc you use and add:

```
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

### Install core command-line tools

The official, recommended way to get Android SDK is to simply download Android
Studio from [developer.android.com/studio]. (You see? There's no `/download`,
there's `/studio`! They're trying so hard to shove Android Studio down our
throats! /s). I don't like installing Android Studio because it's heavy and
because I already have IntelliJ IDEA installed. Why should I bother installing
something I won't use?

So on that page, instead of clicking “Download Android Studio”, scroll down and
find the ["Command line tools only" section] and then download the variant for
your OS. Alternatively, you can use `curl`:

```bash
$ curl --remote-name https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip
```

> To make things simpler, let's assume we're in the `Downloads` directory:
>
> ```bash
> $ cd ~/Downloads
> ```

Now extract the downloaded archive:

```bash
$ unzip commandlinetools-*.zip
```

Extracting the zip created the `cmdline-tools` directory. Let's see what
executable binaries it contains:

```bash
$ ls -1 cmdline-tools/bin
apkanalyzer
avdmanager
lint
profgen
retrace
screenshot2
sdkmanager
```

The program that is most interesting to us now is `sdkmanager`, which allows for
downloading additional Android SDK components. But before doing that, let's move
the `cmdline-tools` directory into the right place.

Let's put this extracted directory into `~/Downloads`, so that we'll be able to
find it at `~/Downloads/cmdline-tools`.

First, create a place where Android SDK will be located. In my case, it's always
`~/androidsdk`, because that's where I like having it.

```bash
$ mkdir ~/androisdk
```

Then create a directory for the command-line tools:

```bash
$ mkdir -p ~/androidsdk/cmdline-tools/latest
```

Now we're ready to copy the contents of the `cmdline-tools` directory into the
final location:

```bash
$ cp -r ~/Downloads/cmdline-tools/* ~/androidsdk/cmdline-tools/latest
```

The reason why I'm using `latest` is that you might want to install other
versions of the command line tools. [Google recommends doing it this
way](https://developer.android.com/tools/releases/cmdline-tools).

### Modify PATH

Finally, you want to add the path where command-line tools live to [PATH], and
also export 2 environment variables. Open `~/.zshrc` and add these lines:

```bash
export ANDROID_HOME="$HOME/androidsdk" # sdk lives here
export ANDROID_USER_HOME="$HOME/.android" # config and tmp files live here
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

`ANDROID_HOME` and `ANDROID_USER_HOME` variables are used by other tools, such
as Android Studio and `flutter` CLI. When they're not defined, those tools often
try to guess other common locations. I think it's a good practice to define them
explicitly.

Reload the shell to apply these changes. For example, if you happen to be using
`zsh`, run `exec zsh`.

> To learn more about the environment variables used by Android SDK, see [this
> page](https://developer.android.com/tools/variables).

## More advanced stuff

At this point, you've got the basics done. You should be able to go to your app
project and run `./gradlew :app:assembleDebug`, or `flutter build apk`, or
similar, and it should _just work_. If you're in hurry, you can stop reading
here!

---

The first build will take quite a long time, and if you observe the logs
carefully, you'll notice that Gradle downloads a bunch of stuff. In the rest of
this post, I'll take a closer look at what exactly is being downloaded, and
what's the purpose of each component.

### Install more tools with sdkmanager

Now you've got yourself a few command-line tools. But that's about it. You still
don't have any build tools (compilers, resource mergers, shrinkers, that sort of
stuff), system images, or an emulator.

To get them, you use
[sdkmanager](https://developer.android.com/studio/command-line/sdkmanager). It's
part of the `cmdline-tools` zip we've just downloaded and it lets you install
everything you might need in your Android development journey. It's located in
`~/androidsdk/cmdline-tools/latest/bin`. BTW, from now on, I'll use
`$ANDROID_HOME` instead of `~/androidsdk` now that it's set.

Now let's run `sdkmanager` again and download stuff that is always needed.

A useful command is `sdkmanager --list_installed`.

### Emulator

It's not necessary to build apps, but most people use it. Let's install it:

```bash
$ sdkmanager --install 'emulator'
```

This will install a bunch of stuff, including the `emulator` binary, under
`$ANDROID_HOME/emulator`. Let's add that directory to PATH so we'll be able to
run `emulator` from anywhere. Open `.zshrc` and append:

```
export PATH="$ANDROID_HOME/emulator:$PATH"
```

### System images

System images are only needed if you plan to use the emulator. You'll save a few
gigs of disk space by not downloading them.

I'm on MacBook powered by Apple Silicon, so I download `arm64-v8` variants:

```bash
$ sdkmanager --install 'system-images;android-33;google_apis;arm64-v8'
```

If you're on a more classic PC box, you'll likely want to replace `arm64-v8`
with `x86_64`.

And to download the same system image, but with Play Store and a few more Google
apps installed:

```bash
$ sdkmanager --install 'system-images;android-33;google_apis_playstore;arm64-v8'
```

### Build tools

To build apps, you need build tools. By default, Android Gradle Plugin (AGP)
takes care of downloading the right version of build tools, so you usually don't
have to care about them, but if you're curious, read on.

As everything else in Android SDK, build tools are installed using `sdkmanager`
(That's what AGP does under the hood as well):

```bash
$ sdkmanager --install 'build-tools;33.0.2'
```

After the installation completes, this particular build tools version can be
found under `$ANDROID_HOME/build-tools/33.0.2`. Some of the most important
executables in that directory are:

- `d8`, which compiles `.class` files (Java bytecode) to `.dex` files (Dalvik
  Executables) that [Android Runtime] can execute
- `aapt2`, which merges all the resources (such as `xml` files asd graphics
  assets) so that they can be packaged into an APK
- `apksigner` which, unsurprisingly, signs APK files

There are many build tools, but each one of them [does one thing and does it
well](https://en.wikipedia.org/wiki/Unix_philosophy). They're invoked by the
build system (usually it's Android Gradle Plugin who calls them) and few people
use them directly (unless they're curious or integrating with an alternative
build system). If you'd like to learn more about the build tools, head over
[here](https://developer.android.com/tools).

Adding build tools binaries to PATH is a bit more involved, because there are
often many versions of them under `$ANDROID_HOME/build-tools`. Here's what I
have in my `~/.zshrc` to automatically export the latest version:

```bash
if [ -d "$ANDROID_HOME/build-tools" ]; then
	build_tools=$(
		command ls "$ANDROID_HOME/build-tools" |
			sort --version-sort --reverse |
			head -n 1
	)

	export PATH="$ANDROID_HOME/build-tools/$build_tools:$PATH"
fi
```

### Platform tools

AGP handles these too.

These tools let you interact with a running Android device, either physical or
virtual.

```bash
$ sdkmanager --install 'platform-tools'
```

After the installation completes, platform tools can be found under
`$ANDROID_HOME/platform-tools`. Again, let's add that directory to PATH:

```bash
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

The most famous binary inside `platform-tools` is definitely `adb`.

### Platforms

AGP handles these too.

First, let's get installation out of our way:

```bash
$ sdkmanager --install 'platforms;android-33'
```

Unsurprisingly, platform `android-33` will be installed under
`$ANDROID_HOME/platforms`.

**But what are platforms?**

A "platform" includes the source code of classes that are part of the OS, so
that IDEs can show the code when you navigate to a symbol from the `android`
namespace, for example `Context` or `Bundle`.

The packages from the `android` top-level namespace in the beginning aren't
built into the APK. They're only placed on the compile classpath, but that's it.
The real implementation is provided by the OS itself. To illustrate this, let's
consider this Java file:

```java
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
  // ...
}
```

The packages starting with `android` are implemented in the OS and made
available to your app at runtime. On the other hand, the `androidx` packages are
"extra" and they are bundled into the APK. It's easy to verify that yourself by
running `apkanalyzer` (from `cmdline-tools`) on the APK.

```bash
./gradlew :app:assembleDebug
cd app/build/outputs/apk/debug
apkanalyzer dex packages app-debug.apk --defined-only | grep '^C' # only classes
```

There'll be lots of classes whose namespace starts with `androidx` namespace,
but ([almost][almost_asterisk]) none of them will be from the `android`
namespace.

## Summary

And that's it for this blogpost.

Last thing: here's [my own shell config file], from where you can easily copy
the PATH-related commands.

Now you've got everything set up, and hopefully you've also learned something
about the SDK's structure. You can go to your Android app project and start
building it.

[developer.android.com/studio]: https://developer.android.com/studio
["Command line tools only" section]: https://developer.android.com/studio#command-line-tools-only
[Eclipse Temurin]: https://adoptium.net/temurin/releases
[PATH]: https://en.wikipedia.org/wiki/PATH_(variable)
[Android Runtime]: https://source.android.com/docs/core/runtime
[almost_asterisk]: https://stackoverflow.com/q/76694804/7009800
[my own shell config file]: https://github.com/bartekpacia/dotfiles/blob/6cc3a37e7a8330b760a4810fc49c31ab8a56e9f3/dot/shrc#L32-L52
