As a mobile developer, I create AVDs quite often. I've come to hate this
experience because:

- having to start Android Studio (or IntelliJ IDEA) every time I want to do
  anything with an AVD is annyoing
- no easy way to share emulator config with other developers and testers

In this article I'll show how I manage AVDs from the terminal. You don't even
need to have Android Studio / IntellIJ installed – [Android command-line
tools](https://developer.android.com/studio/command-line) are enough.

### Creating AVD

To view installed system images:

```bash
sdkmanager --list_installed | grep "system-images"
```

To create an AVD:

```bash
avdmanager create avd \
	--sdcard '8192M' \ # or '8G'
	--package 'system-images;android-33;google_apis;arm64-v8a' \
	--name 'Pixel_7_API_33' \
	--device 'pixel_7'
```

> 💡 To get the list of available device profiles that can be passed to the
> `--device` argument, run `avdmanager list devices`. Drop in a `-c` flag to get
> nicer output.

By default, it will create a new AVD in `$HOME/.android/avd`. Let's see:

```bash
$ ls -h ~/.android/avd
Pixel_7_API_33.avd    Pixel_7_API_33.ini
```

### Running AVD

To run the newly created AVD:

```bash
emulator @Pixel_7_API_33
```

I don't like the above command – it logs all output to the terminal tab in which
you run it, rendering it unusable. I prefer the below:

```bash
(emulator @Pixel_7_API_33 1> /dev/null 2>&1 &) > /dev/null 2>&1
```

> 💡 Learn more about [commonly used options] and [advanced options].

</aside>

### Customizing AVD

The AVD that we've created works, but there are some problems with it. Let's fix
them.

The first problem is that you can't use your computer's keyboard to input text
in the emulator. The fix is quite simple. Change `hw.keyboard = no` to
`hw.keyboard = yes` in `~/.android/avd/Pixel_7_API_33.avd/config.ini`.

The second problem is the default values of RAM and VM heap size, which are too
low. To increase them, edit `hw.ramSize` and `vm.heapSize` in the same
`config.ini` file. Unfortunately, `avdmanager create avd` doesn't accept options
to change these values when creating the AVD.

I find the following values reasonable:

```
hw.ramSize = 4096M
vm.heapSize = 1024M
```

### Changing GPS coordinates

There's a `AVD.conf` file in `~/.android/avd/Pixel_7_API_33.avd`which by default
contains the GPS coordinates. By default, they point to Google's HQ in
California.

```
[perAvd]
loc\altitude=5
loc\heading=0
loc\latitude=37.422
loc\longitude=-122.084
loc\velocity=0
```

You can edit the coordinates with any text editor and the changes will be
immediately picked up by the AVD.

### Disabling saving quick-boot state on exit

I don't like the quick-boot feature. It's unreliable and has weird bugs.

To get rid of this, add this line to `AVD.conf`:

```
set\saveSnapshotOnExit=1
```

<aside>
💡 Here 1 means “don't save quick-boot state”, and 0 means “save quick-boot state”. Kind of like Unix exit codes, where 0 means success and non-zero means failure.

</aside>

### Removing snapshots

Snapshots live in the `snapshots` directory in your AVD's directory. Removing
them is simple:

```
rm -rf ~/.android/avd/Pixel_7_API_33.avd/snapshots
```

**Learn more**

- https://developer.android.com/studio/run/advanced-emulator-usage
- https://learn.microsoft.com/en-us/xamarin/android/get-started/installation/android-emulator/device-manager?tabs=macos&pivots=macos

[commonly used options]: https://developer.android.com/studio/run/emulator-commandline#common
[advanced options]: https://developer.android.com/studio/run/emulator-commandline
