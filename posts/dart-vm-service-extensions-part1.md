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
compiled. In the former case, the Dart VM behaves more like a JVM. In the
latter, it's similar to Go's runtime.

# What are service extensions?

Dart VM hosts a VM service, which is essentially a WebSocket server that you can
communicate with using the _[Dart VM Service Protocol]._

Service extensions is a mechanism that makes it easy to create WebSocket-based
[JSON-RPC](https://www.jsonrpc.org) servers and clients in a Dart program
without using any third-party packages.

Most of the core service extensions are implemented in the VM itself, but some
Dart's built-in libraries, such as `dart:io`, contribute their own service
extensions. From the developer's point of view, there's no difference.

The VM Service Protocol is extensible - developers can write their own service
extensions. That's what I'm going to show in this post.

# Why service extensions are useful?

Service extensions provide official hook points to a running Dart VM. Thanks to
them, we're able to query and modify its state, and extend it with new
functionality.

You most likely will never find a use case for a Dart VM service extension when
developing _yet another app_. They come useful in the more “frameworky”
projects, often developer tooling-related.

Show how many default service extensions are there (in Observatory/DevTools)

I first learned about and implemented service extensions when I was working on a
[new feature](https://github.com/leancodepl/patrol/pull/593) for a [custom test
framework for Flutter](https://github.com/leancodepl/patrol). That feature has
been ditched for a while now, but the service extension mechanism seemed pretty
interesting to me, and not well-known. There are also no good resources on the
internet about it, so I decided to share my knowledge and create one.

# New service extension in a Dart program

Let's implement our first simple service extension. To do so, we need a program
that has some internal state. We'll bolt our service extension on top of it to
query that state.

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
is a post about service extensions, I'll use them (Service extension actually
work over WebSockets). Here's how I image `spy` to work when run:

```
$ dart run spy.dart
The printer program has counted to 21
```

Looks pretty basic, but it's enough for now. Everything needed to implement a
new service extension is in the built-in [`dart:developer`][dartdeveloper]
package.

---

### Implementing `printer`

The first thing to do is pick a name for our new service extension. I went with
`ext.printer.getCount` (custom service extensions must start with `ext`). Then I
register the `_getCountHandler` function to run when the extension is called.
I'll implement it shortly.

```dart
const String extensionName = 'ext.printer.getCount';
developer.registerExtension(extensionName, _getCountHandler);
```

`_getCountHandler` must conform to the
[`ServiceExtensionHandler`][ServiceExtensionHandler] typedef. In our case, it's
going to simply return a small JSON containing `count`:

```dart
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

Service extensions are isolate specific, so we will be required to know the
isolate ID where the service extension is registered. Let's print the ID of the
current (main) isolate so we can copy it later:

```dart
final String isolateId = developer.Service.getIsolateID(Isolate.current)!;
print('Registered service extension $extensionName in $isolateId');
```

And that's it for the `printer` program. [Here is its full
code](https://github.com/bartekpacia/dart-vm-service-extensions/blob/master/dart_sample/bin/printer.dart).
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

Finally, let's call the service extension. Here we pass the `isolateId` that we
got as the second argument on the command line:

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

The program will very likely finish before we get the response. Let's use an
ugly-but-working fix:

```dart
// Simply, hacky way to keep running until the response is received.
await Future.delayed(const Duration(seconds: 1));
// Let's also close the socket.
socket.close();
```

That's it! Now we can run `spy` and pass it the values we got from `printer`s
output. Remember to replace `http` with `ws`!

```
dart run bin/spy.dart ws://127.0.0.1:8181/FmMJoBzneFU\=/ isolates/718812529134167
Calling service extension ext.printer.getCount...
Got response from ext.printer.getCount: {status: printing, count: 2}
```

Good - we got the response. It works.

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

Create an instance of `VmService`, which provides a higher-level type-safe
interface to a VM remote service.

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

You'll be yelled at by the analyzer for not having `controller`. Let's put this
code before defining `vmService` , but after defining `socket`:

```dart
final StreamController<dynamic> controller = StreamController<dynamic>();
final Completer<void> streamClosedCompleter = Completer<void>();
socket.listen(
  (dynamic data) => controller.add(data),
  onDone: () => streamClosedCompleter.complete(),
);
```

# New service extension in a Flutter app

The previous example was a toy one. The real strength of service extensions can
be seen when working on developer tools for Flutter.

Actually, many of the universally praised development-time features that Flutter
is known for – like [Hot Reload] and [Hot Restart] – are implemented as Dart VM
Service extensions. [Flutter Engine also has a few service
extensions](https://github.com/flutter/flutter/wiki/Engine-specific-Service-Protocol-extensions).
If you're curious and would like to dive deeper in its internals,
[`vmservice.dart`](https://github.com/flutter/flutter/blob/3.19.0/packages/flutter_tools/lib/src/vmservice.dart)
file in the
[`flutter_tools`](https://github.com/flutter/flutter/tree/master/packages/flutter_tools)
package is a good starting point.

The main difference between the previous pure-Dart example and this one is that
in case of a Flutter app (running in debug mode), the VM service connection
already exists – it's automatically estabilished by the `flutter` tool when you
`flutter run` (or `flutter attach`). We'll take advantage of that and won't
create a new one.

Of course, you _could_ create another VM service connection, but I don't see a
reason why you'd want to do that.

---

Before starting coding, let's stop and think what we want to achieve. There are
2 basic scenarios we can excercise:

- The service extension runs in the app, host machine connects to it. This
  enables the host to reach into the app and explore its internal state.
- The service extensions runs on the host machine, the app connects to it. This
  enables our app to reach out to the outside world. This is useful if something
  can't be done from withing the device (e.g. executing some powerful `adb`
  commands), but is trivial to do from the host.

I'll show both.

# Service extension running in the Flutter app

Let's get our hands dirty again by implementing a counter app that will share
its state over service extension!

# Summary

That's all for this post. I hope you find it insightful.

[Dart VM Service Protocol]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md
[repo]: https://github.com/bartekpacia/dart-vm-service-extensions
[ServiceExtensionHandler]: https://api.dart.dev/stable/3.3.0/dart-developer/ServiceExtensionHandler.html
[dartdeveloper]: https://api.dart.dev/stable/dart-developer/dart-developer-library.html
[Hot Reload]: https://github.com/flutter/flutter/blob/3.19.0/packages/flutter_tools/lib/src/vmservice.dart#L211-L226
[Hot Restart]: https://github.com/flutter/flutter/blob/3.19.0/packages/flutter_tools/lib/src/vmservice.dart#L228-L239
[^slava]: Taken from https://mrale.ph/dartvm. It's a great website.
