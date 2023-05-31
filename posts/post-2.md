---
date: 20220527
---

# Suckless Android SDK setup

Android SDK is one of the first things I set up on a new computer. This post is
a reference for future me and for anyone who wants to do it right and learn
something along the way.

This post is for you if you:

- need Android SDK, but don’t want to install the bulky Android Studio
- want to know more about what Android SDK provides and have a rough idea of its
  structure

## Preface and rant

Why am I writing this post? Surely there are official guides on installing
Android SDK?

Well, I think that the official, commonly recommended way of downloading Android
SDK sucks. More specifically, recommending everyone to install Android Studio
sucks.

I'm under the impression that the official docs are optimized for the lowest
common denominator type of person. That's not a bad thing when you're just
getting started with Android development, but after doing the setup of SDK a few
times, I want to know more about what I am doing and why I am doing it. And
that's what the official docs fall short of.

I also strongly believe that knowing something more about the tools you're
depending on everyday makes you a better developer.

## Install core command-line tools

The official, recommended way to get Android SDK is to simply download Android
Studio from [developer.android.com/studio]. (You see? There’s no `/download`,
there’s `/studio`! They’re trying so hard to shove Android Studio down our
throats! /s). I don’t like installing Android Studio because it’s heavy and
because I already have IntelliJ IDEA installed. Why should I bother installing
something I won’t use?

So on that page, instead of clicking “Download Android Studio”, scroll down and
find the ["Command line tools only" section] and then download the variant for
your OS. Alternatively, you can use `curl`.

```bash
$ curl --remote-name https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip
```

> To make things simpler, let’s assume we’re in the `Downloads` directory:
>
> ```bash
> $ cd ~/Downloads
> ```

Now extract the downloaded archive:

```bash
$ unzip commandlinetools-*.zip
```

Extracting the zip created the `cmdline-tools` directory. Let’s see what
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
downloading additional Android SDK components. But before doing that, let’s move
the `cmdline-tools` directory into the right place.

Let’s put this extracted directory into `~/Downloads`, so that we’ll be able to
find it at `~/Downloads/cmdline-tools`.

First, create a place where Android SDK will be located. In my case, it’s always
`~/androidsdk`, because that’s where I like having it.

```bash
$ mkdir ~/androisdk
```

Then create a directory for the command-line tools:

```bash
$ mkdir -p ~/androidsdk/cmdline-tools/latest
```

Now we’re ready to copy the contents of the `cmdline-tools` directory into the
final location:

```bash
$ cp -r ~/Downloads/cmdline-tools/* ~/androidsdk/cmdline-tools/latest
```

The reason why I’m using `latest` is that you might want to install other
versions of the command line tools. [Google recommends doing it this
way](https://developer.android.com/tools/releases/cmdline-tools).

# Modify PATH

Before going further, you want to add the path where command-line tools are to
[PATH], because…

```
$ sdkmanager
zsh: command not found: sdkmanager
```

To fix this, open your `.bashrc`, `.zshrc`, or whateverrc you have and append:

```bash
export ANDROID_HOME="$HOME/androidsdk" # sdk lives here
export ANDROID_USER_HOME="$HOME/.android" # config and tmp files live here
```

Reload the shell to apply these changes. For example, if you happen to be using
`zsh`, run `exec zsh`.

> To learn more about the environment variables used by Android SDK, see [this
> page](https://developer.android.com/tools/variables).

## Install more tools with sdkmanager

Now you’ve got yourself a few command-line tools. But that’s about it. You still
don’t have any build tools (compilers, resource mergers, shrinkers, that sort of
stuff), system images, or an emulator.

To get them, you use
[sdkmanager](https://developer.android.com/studio/command-line/sdkmanager). It’s
part of the `cmdline-tools` zip we’ve just downloaded and it lets you install
everything you might need in your Android development journey. It’s located in
`~/androidsdk/cmdline-tools/latest/bin`. BTW, from now on, I’ll use
`$ANDROID_HOME` instead of `~/androidsdk` now that it’s set.

Now let’s run `sdkmanager` again and download stuff that is always needed.

A useful command is `sdkmanager --list_installed`.

### System images

System images are only needed if you plan to use the emulator. You’ll save a few
gigs of disk space by not downloading them.

Most people do want the emulator, though, so let’s install it:

```bash
$ sdkmanager --install 'emulator'
```

I’m on MacBook powered by Apple Silicon, so I download `arm64-v8` variants. If
you’re on a more classic PC box, you’ll likely want to replace `arm64-v8` with
`x86_64`.

```bash
$ sdkmanager --install 'system-images;android-33;google_apis;arm64-v8'
```

And to download the same system image, but with Play Store and a few more Google
apps installed:

```bash
$ sdkmanager --install 'system-images;android-33;google_apis_playstore;arm64-v8'
```

### Build tools

To build apps, you need build tools.

```bash
$ sdkmanager --install 'build-tools;33.0.2'
```

After the installation completes, build tools can be found under
`$ANDROID_HOME/build-tools/33.0.2`.

```bash
ls -1 "$ANDROID_HOME/build-tools/33.0.2"
```

There’s lots in there. Some of the most important executables in that directory
are:

- `d8`, which compiles `.class` files (Java bytecode) to `.dex` files (Dalvik
  Executables) that [Android Runtime] can execute
- `aapt2`, which merges all the resources (such as `xml` files asd graphics
  assets) so that they can be packaged into an APK
- `apksigner`, which, unsurprisingly, signs APK files

There are many build tools, but each of them [does one thing and does it
well](https://en.wikipedia.org/wiki/Unix_philosophy). They’re invoked by the
build system (usually it's Android Gradle Plugin who calls them) and nobody uses
them directly (unless you’re curious or integrating with an alternative build
system).

If you’d like to learn more about the build tools, head over
[here](https://developer.android.com/tools).

### Platform tools

These tools let you interact with the OS itself.

```bash
$ sdkmanager --install 'platform-tools'
```

After the installation completes, platform tools can be found under
`$ANDROID_HOME/platform-tools`.

```bash
ls -1 "$ANDROID_HOME/build-tools/33.0.2"
```

The most famous of them is definitely `adb`.

### Platforms

First, let's get installation out of our way:

```bash
$ sdkmanager --install 'platforms;android-33'
```

But what are platforms?

"Platform" includes the source of classes that are part of the OS, so that IDEs
can show the code when you navigate to a symbol from the `android` namespace.

The packages from with `android` in the beginning aren't built into the APK.
They're only place on the compile classpath, but that's it. The real
implementation is provided by the OS itself. To illustrate this, let's consider
this Java file:

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
"extra" and they are, bundled into the APK.

[developer.android.com/studio]: https://developer.android.com/studio
["Command line tools only" section]: https://developer.android.com/studio#command-line-tools-only
[PATH]: https://en.wikipedia.org/wiki/PATH_(variable)
[Android Runtime]: https://source.android.com/docs/core/runtime
