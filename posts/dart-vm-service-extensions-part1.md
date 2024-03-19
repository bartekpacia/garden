---
date: 20240310
---

# Writing a custom Dart VM service extension (part 1)

In this post, I'll take a closer look at Dart VM's service extensions mechanism
and explain what service extensions are and why they are useful in certain
situations. I'll also show how to implement a new, simple service extension in a
pure Dart program and in a Flutter app.

# The Dart language

Dart is a flexible language. It not only supports many target platforms and CPU
architectures, but it can also be executed in a few different ways.

You might have heard the name “Dart Virtual Machine” tossed around. This name is
a leftover from the times when Dart code could only be JIT compiled, which is no
longer true – we've had AOT compilation for many years now. Currently, Dart VM
is a virtual machine in a sense that it provides runtime environment for a
high-level programming language[^slava]. Dart code can be JIT compiled or AOT
compiled. I think that a useful - but likely not entirely true[^nerds] –
simplification is that in the former case, the Dart VM behaves more like a JVM.
In the latter, it's similar to Go's runtime, where both runtime, stdlib, and
your code are statically compiled into the same binary.

# What are service extensions?

Dart VM hosts a VM service, which is essentially a WebSocket server that you can
communicate with using the [JSON-RPC]-based _[Dart VM Service Protocol]._

Service extensions is a mechanism that enables developers to add custom
functionality to that server (think "custom endpoints") without using any
third-party packages.

Let's imagine a running Dart VM with 3 isolates and some service extensions:

![](/assets/img/light/dart-vm-detailed.png)

![](/assets/img/dark/dart-vm-detailed.png)

There's a couple interesting points to take a note of:

- There's a single VM service[^doubt]

- Service extensions are bound to the isolate they were registered in

- The same extension can be registered in many isolates

So it follows that the client must always pass ID of the isolate when calling a
service extension.

# Why service extensions are useful?

Service extensions provide official hook points to a running Dart VM. Thanks to
them, we're able to query and modify its state, and extend it with new
functionality.

You most likely will never find a use case for a Dart VM service extension when
developing _yet another app_. They come useful in the more “frameworky”
projects, often developer tooling-related.

Actually, many of the universally praised development-time features that Flutter
is known for – like [Hot Reload] and [Hot Restart] – are implemented as Dart VM
Service extensions.
[Flutter Engine also has a few service extensions](https://github.com/flutter/flutter/wiki/Engine-specific-Service-Protocol-extensions).
If you're curious and would like to dive deeper in its internals,
[`vmservice.dart`](https://github.com/flutter/flutter/blob/3.19.0/packages/flutter_tools/lib/src/vmservice.dart)
file in the
[`flutter_tools`](https://github.com/flutter/flutter/tree/master/packages/flutter_tools)
package is a good starting point.

Service extensions are also essential to Flutter's new [DevTools Extensions]
system.

Dart, apart from service extensions defined in [Dart VM Service Protocol], also
has [Dart Development Service Protocol] and [Dart VM Service Protocol
Extension].

I first learned about and implemented service extensions when I was working on a
[new feature](https://github.com/leancodepl/patrol/pull/593) for a
[custom test framework for Flutter](https://github.com/leancodepl/patrol). That
feature has been ditched for a while now, but the service extensions mechanism
seemed pretty interesting to me, and not well-known, so I decided to share my
knowledge.

# New service extension in a Dart program

Let's implement our first simple service extension.

To do so, we need a program that has some internal state. Then, we'll expose
that state through a service extension, and finally build another program that
will call our service extension and query that internal state.

> All code [is available in the GitHub repo][repo] in the `dart_sample`
> directory.

### What we'll build

I'll start with a very simple `printer` program. All it does is incrementing a
global `count` variable every second and printing it to standard output,
infinitely.

```dart
var count = 0;

void main() {
  () async {
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      count++;
      print('Count: $count');
    }
  }();
}
```

Here's its output after 3 seconds:

```dart
$ dart run printer.dart
Count: 0
Count: 1
Count: 2
```

Now imagine that you want to write another Dart program, let's call it `spy`,
that would be able to ask `printer` about its state. There are lots of ways to
it – HTTP server, WebSockets, Unix Domain Sockets, and many more, but since this
is a post about service extensions, I'll use them (service extension actually
work over WebSockets). Here's how I imagine `spy` to work when run:

```
$ dart run spy.dart
The printer program has counted to 21
```

![](/assets/img/light/dart-vms.png)

![](/assets/img/dark/dart-vms.png)

Looks pretty basic, but it's enough for now. Everything needed to implement a
new service extension is in the built-in [`dart:developer`][dartdeveloper]
package.

---

### Implementing `printer`

The first thing to do is pick a name for our new service extension. I went with
`ext.printer.getCount` – custom service extensions must start with `ext`:

```dart
const String extensionName = 'ext.printer.getCount';
```

Then I register the `_getCountHandler` function to run when the extension is
called. `_getCountHandler` must conform to the
[`ServiceExtensionHandler`][ServiceExtensionHandler] typedef. In our case, it's
going to simply return a small JSON containing `count`:

```dart
developer.registerExtension(extensionName, _getCountHandler);

Future<developer.ServiceExtensionResponse> _getCountHandler(
  String method,
  Map<String, String> parameters,
) async {
  final Map<String, dynamic> result = {
    'status': 'printing',
    'count': count,
  };

  return developer.ServiceExtensionResponse.result(jsonEncode(result));
}
```

**Remember that service extensions are isolate specific**. When you call
[`developer.registerExtension(method, handler)`][registerExtension] it registers
the extension in the isolate where it was called. The clients wishing to
interact with our extension will be required to know the ID of the that isolate.
Let's print the ID of the current (in our case there is only one - the `main`
isolate) isolate so we can copy it later:

```dart
final String isolateId = developer.Service.getIsolateID(Isolate.current)!;
print('Registered service extension $extensionName in $isolateId');
```

And that's it for the `printer` program.
[Here is its full code](https://github.com/bartekpacia/dart-vm-service-extensions/blob/master/dart_sample/bin/printer.dart).
Now, let's make sure it works and that our extension is registered. To do it,
run `priner` first with Dart VM service enabled (it's disabled by default) by
passing the `--enable-vm-service` flag to `dart run`:

```
$ dart run --enable-vm-service bin/printer.dart
The Dart VM service is listening on http://127.0.0.1:8181/FmMJoBzneFU=/
The Dart DevTools debugger and profiler is available at: http://127.0.0.1:8181/FmMJoBzneFU=/devtools?uri=ws://127.0.0.1:8181/FmMJoBzneFU=/ws
Count: 0
Registered service extension ext.printer.getCount in isolates/718812529134167
Count: 1
Count: 2
```

We will need two things from this output: the address of the VM service and the
ID of the isolate where the service extension is registered:

- VM service address is `ws://127.0.0.1:8181/FmMJoBzneFU=/` (replace `http` with
  `ws`)
- isolate ID is `isolates/718812529134167` (there's only one isolate in our
  program)

### Implementing `spy` – first version

Now we're getting to the cool stuff. The `spy` program will connect to the Dart
VM Service that is running the `printer` program, and call our own service
extension that will return the current `count` value.

> A quick reminder that the whole code is [available on GitHub][repo]. The `spy`
> program is available in three versions - `spy_basic`, `spy`, and `spy_best`.
> Right now I'm explaining implementation of `spy_basic`.

As I already said, we need two inputs: VM service address (needed to establish a
WebSockets connection) and isolate where the service extension is registered.

```dart
import 'dart:io' as io;

Future<void> main(List<String> args) async {
  final String webSocketUrl = args[0];
  final String isolateId = args[1];

  final io.WebSocket socket = await io.WebSocket.connect(webSocketUrl);
}
```

After creating a socket, let's listen on it:

```dart
socket.listen(
  (dynamic data) {
    var encoder = JsonEncoder.withIndent('  ');
    final response = encoder.convert(jsonDecode(data));
    print('Got response from ext.printer.getCount:\n$response');
  },
);
```

Finally, let's call the service extension. In `params` we pass the `isolateId`
that we got as the second argument on the command line:

```dart
print('Calling service extension ext.printer.getCount...');
socket.add(jsonEncode({
  'jsonrpc': '2.0',
  'id': 1,
  'method': 'ext.printer.getCount',
  'params': {'isolateId': isolateId},
}));

socket.close();
```

This program will very likely finish before we get a response. Let's put some
duct tape on it:

```dart
// Simply, hacky way to keep running until the response is received.
await Future.delayed(const Duration(seconds: 1));
// Let's also close the socket.
socket.close();
```

---

That should be it. Let's run both programs now, starting with `printer`.

```
$ dart run --enable-vm-service bin/printer.dart
The Dart VM service is listening on http://127.0.0.1:8181/IEtIpIQOzi4=/
The Dart DevTools debugger and profiler is available at: http://127.0.0.1:8181/IEtIpIQOzi4=/devtools?uri=ws://127.0.0.1:8181/IEtIpIQOzi4=/ws
Registered service extension ext.printer.getCount in isolates/6010531716406367
Count: 0
Count: 1
```

Then, run `spy`, passing it the values we got from `printer`'s initial output.
Remember to replace `http` with `ws` in the VM service address.

```
dart run bin/spy.dart ws://127.0.0.1:8181/IEtIpIQOzi4=/ isolates/6010531716406367
Calling service extension ext.printer.getCount...
Got response from ext.printer.getCount: {status: printing, count: 2}
```

It works - we got the response! [Here's the full code of spy][spy_basic].

# More safety thanks to the vm_service package

I said in the beginning that everything needed to implement a new service
extension is built in – no external packages are needed. As you can see above,
that's 100% true, but there are a few problems:

- No type safety - it's all strings flying back and forth
- Low discoverability - no documentation on hover
- Request-response - you need to assign IDs to requests yourself and then
  implement some loop to handle them

When your service extension grows in complexity, you'll sooner or later end up
writing your own little library around basic VM service features such as getting
the VM, finding the ID of the main isolate, a simple event loop, etc. That's
where the [vm_service](https://pub.dev/packages/vm_service) package comes into
play – it provides many basic building blocks that make writing a service
extension easier.

### Implementing `spy` – second version

Let's rewrite `spy` using the `vm_service` package. Beginning is mostly the
same:

```dart
import 'package:vm_service/vm_service.dart' as vm_service;

Future<void> main(List<String> args) async {
  final String webSocketUrl = args[0];
  final String isolateId = args[1];

  final io.WebSocket socket = await io.WebSocket.connect(webSocketUrl);
}
```

Now we need to create a stream controller and a completer. They are required by
`VmService`, which we'll create shortly.

```dart
final StreamController<dynamic> controller = StreamController<dynamic>();
final Completer<void> streamClosedCompleter = Completer<void>();
socket.listen(
  (dynamic data) => controller.add(data),
  onDone: () => streamClosedCompleter.complete(),
);
```

Finally, create an instance of [`VmService`][VmService], which provides a
higher-level type-safe interface to a VM remote service.

```dart
// VmService is a reference to the VM service that is (possibly) running in a
// different VM
final vm_service.VmService vmService = vm_service.VmService(
  controller.stream,
  socket.add,
  disposeHandler: () => socket.close(),
  streamClosed: streamClosedCompleter.future,
);
```

Finally, we can call the service extension using
[`VmService.callServiceExtension(method, {isolateId, args})`][callServiceExtension]:

```dart
final serviceExtensionName = 'ext.printer.getCount';
print('Calling service extension $serviceExtensionName...');
final vm_service.Response response = await vmService.callServiceExtension(
  serviceExtensionName,
  isolateId: isolateId,
);
print('Got response from $serviceExtensionName: ${response.json}');
socket.close();
```

[Full code here][spy]. This version of our "spy" VM service client is actually
more lines of code – but it is one time boilerplate that provides a good
foundation if your service-extensions-based project grows. Notice how we no
longer care about low-level details like calling `toJson()` on a map, specifying
protocol, or assigning ids to messages.

> One very cool improvement that can be made to this program is [automatic
> retrieval of the main isolate ID][auto_main_isolate]. Since it's very similar
> I won't explain it in detail again, instead I'll just [link to its
> code][spy_best].

# Summary

That's all for this post. It's been in my "writing cabinet" since May 2023, and
I've been procrastinating _so much_ on it. That's mainly because I also wanted
to talk about service extensions in the context of Flutter, but it would make
the post 50% longer. I still plan to do it – but in part 2. For now, it is what
it is.

But before we split, let me whet your appetite for part 2.

### New service extension in a Flutter app

The examples I showed were, let's face it, toy ones. The real strength of
service extensions can be seen when working on developer tools for Flutter.

The main difference between the previous pure-Dart examples and Flutter app is
that in case of a Flutter app (running in debug mode), the VM service connection
already exists – it's automatically estabilished by the `flutter` tool when you
`flutter run` (or `flutter attach`). We'll take advantage of that and won't
create a new one[^two_connections].

In case of a Flutter app, service extensions enable the following 2 scenarios:

- **Service extension runs in the app**, host machine connects to it. This
  enables the host to reach into the app and explore its internal state.
- **Service extension runs on the host machine**, the app connects to it. This
  enables the app to _reach out_ to the grand outside world. This is useful if
  something can't be done from withing the device (e.g. executing some powerful
  `adb` commands), but is trivial to do from the host.

So yeah, in that future blog post I'll show both. Done is better than perfect,
as they say, ha!

### The end

I hope you enjoyed it! See you soon in part 2.

[JSON-RPC]: https://www.jsonrpc.org
[Dart VM Service Protocol]:
  https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md
[Dart VM Service Protocol Extension]:
  https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service_extension.md
[Dart Development Service Protocol]:
  https://github.com/dart-lang/sdk/blob/main/pkg/dds/dds_protocol.md
[repo]: https://github.com/bartekpacia/dart-vm-service-extensions
[ServiceExtensionHandler]:
  https://api.dart.dev/stable/3.3.0/dart-developer/ServiceExtensionHandler.html
[dartdeveloper]:
  https://api.dart.dev/stable/3.3.0/dart-developer/dart-developer-library.html
[spy_basic]:
  https://github.com/bartekpacia/dart-vm-service-extensions/blob/master/dart_sample/bin/spy_basic.dart
[spy]:
  https://github.com/bartekpacia/dart-vm-service-extensions/blob/master/dart_sample/bin/spy.dart
[spy_best]:
  https://github.com/bartekpacia/dart-vm-service-extensions/blob/master/dart_sample/bin/spy_best.dart
[registerExtension]:
  https://api.dart.dev/stable/3.3.0/dart-developer/registerExtension.html
[callServiceExtension]:
  https://pub.dev/documentation/vm_service/14.1.0/vm_service/VmService/callServiceExtension.html
[VmService]:
  https://pub.dev/documentation/vm_service/14.1.0/vm_service/VmService-class.html
[Hot Reload]:
  https://github.com/flutter/flutter/blob/3.19.0/packages/flutter_tools/lib/src/vmservice.dart#L211-L226
[Hot Restart]:
  https://github.com/flutter/flutter/blob/3.19.0/packages/flutter_tools/lib/src/vmservice.dart#L228-L239
[DevTools Extensions]: https://docs.flutter.dev/tools/devtools/extensions
[auto_main_isolate]:
  https://github.com/bartekpacia/dart-vm-service-extensions/blob/98092cef91c4921c175b27682666d2056dda287e/dart_sample/bin/spy_best.dart#L31-L37

[^slava]:
    Taken from [https://mrale.ph/dartvm](https://mrale.ph/dartvm). It's a great
    website.

[^nerds]:
    If some experienced Dart hacker is reading this post, please do let me know
    how far from the truth I am.

[^doubt]:
[^two_connections]:
    Of course, you _could_ create another VM service connection, but I don't see
    a reason why you'd want to do that. If you have an idea, drop me a line!
