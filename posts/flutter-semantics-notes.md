---
date: 20231130
title: Semantics in Flutter - under the hood
description: Random notes about the semantics mechanism.
---

# Semantics in Flutter - under the hood

Findings:

1. `SemanticsNode`
   [already has a Key in it](https://github.com/flutter/flutter/blob/6673fe5cb14aebc14b975d3922ee58ac05c449b7/packages/flutter/lib/src/semantics/semantics.dart#L1704-L1708C17)!
   1. Could it just be uploaded to the engine?
   2. Nah, because this key is associated with the `Semantics` itself???
2. PRs that added support for `tooltip` in semantics. Something similar could be
   done with `identifier`.
   1. framework part https://github.com/flutter/flutter/pull/87684
   2. engine part
      1. original https://github.com/flutter/engine/pull/27893
   3. relanded https://github.com/flutter/engine/pull/28211
3. [PR that optimized semantics](https://github.com/flutter/flutter/pull/104281).
   Has some stats about how many “semantics” there are in big apps.

# How does semantics flow from the Framework to the Engine?

## In the framework

1. Developer creates a [`Semantics`][Semantics] widget, passes
   [`SemanticsProperties`][SemanticsProperties] to it
2. The [Semantics] widget [creates its render object][Semantics renderobject] –
   [RenderSemanticsAnnotations]
3. The [`RenderSemanticsAnnotations`][RenderSemanticsAnnotations] render object
   calls
   [`markNeedsSemanticsUpdate()`](https://api.flutter.dev/flutter/rendering/RenderObject/markNeedsSemanticsUpdate.html).
   This method is inherited from the [RenderObject] abstract class
4. `markNeedsSemanticsUpdate()`
   [adds the render object](https://github.com/flutter/flutter/blob/c0b21b16ef84cad520af81bf3431a928a05f3335/packages/flutter/lib/src/rendering/object.dart#L3598)
   to `PipelineOwner._nodesNeedingSemantics`.

Also, every `RenderObject` manages its own `SemanticConfiguration`.

5. when _somebody_ wants the `RenderObject` to tell _them_ about its semantics,
   it calls `describeSemanticsConfiguration` and passes (TODO)

---

At some later point, a new frame is scheduled by the engine. This is handled by
[RendererBinding] in the
[persistent frame callback](https://github.com/flutter/flutter/blob/3.16.0/packages/flutter/lib/src/rendering/binding.dart#L456-L459)
that
[it registered](https://github.com/flutter/flutter/blob/3.16.0/packages/flutter/lib/src/rendering/binding.dart#L46).
This callback calls `RendererBinding`'s [`drawFrame()`][drawFrame], which drives
the frame rendering pipeline. In one of the last stages of this pipeline, it
[calls](https://github.com/flutter/flutter/blob/cb9a3f698c7d68fb6ebf1a91364c32d881ec5e3e/packages/flutter/lib/src/rendering/binding.dart#L589)[`PipelineOwner.flushSemantics()`][flushSemantics].
This gathers `_nodesNeedingSemantics`.

Finally, [`SemanticsOwner.sendSemanticsUpdate()`][sendSemanticsUpdates]
[is called](https://github.com/flutter/flutter/blob/c0b21b16ef84cad520af81bf3431a928a05f3335/packages/flutter/lib/src/rendering/object.dart#L1306).
This function does (quite some stuff), but most importantly, it finally
[calls](https://github.com/flutter/flutter/blob/e33d4b86270e3c012ba13d68d6e90f2eabc4912b/packages/flutter/lib/src/semantics/semantics.dart#L3418)
[`SemanticsUpdateBuilder.build()`][SBU build] to obtain a
[`SemanticsUpdate`][SemanticsUpdate].

> 💡 [SemanticsUpdateBuilder] is an abstract class from the engine. It's
> implemented in C++
> ([header](https://github.com/flutter/engine/blob/3.16.0/lib/ui/semantics/semantics_update_builder.h#L18))
> ([source](https://github.com/flutter/engine/blob/3.16.0/lib/ui/semantics/semantics_update_builder.cc#L133)).

Then, the
[SemanticsOwner.onSemanticsUpdate](https://github.com/flutter/flutter/blob/3.16.0/packages/flutter/lib/src/semantics/semantics.dart#L3257)
callback is called and the `SemanticsUpdate` is passed to it as an argument.

(omitted some calls)

Then that `SemanticsUpdate` is passed to the engine by
[calling](https://github.com/flutter/flutter/blob/3.16.0/packages/flutter/lib/src/rendering/binding.dart#L244-L246)
`RenderView.updateSemantics()`.

### In the engine

TODO, but generally:

- first, the SemanticsUpdate lands in Engine's C++ code, and then
- it is delivered to the appropriate embedder APIs
- on Android, JNI is heavily used

### Naming observations

- Methods that start with "handle", e.g. `handlePlatformBrightnessChanged`, are
  callbacks to be run when the engine says so

[Semantics]: https://api.flutter.dev/flutter/widgets/Semantics-class.html
[SemanticsProperties]: https://api.flutter.dev/flutter/semantics/SemanticsProperties-class.html
[Semantics renderobject]: https://github.com/flutter/flutter/blob/3.16.0/packages/flutter/lib/src/widgets/basic.dart#L7307-L7317
[RenderSemanticsAnnotations]: https://api.flutter.dev/flutter/rendering/RenderSemanticsAnnotations-class.html
[SemanticsNode]: https://api.flutter.dev/flutter/semantics/SemanticsNode-class.html
[SemanticsUpdateBuilder]: https://api.flutter.dev/flutter/dart-ui/SemanticsUpdateBuilder-class.html
[SemanticsUpdateBuilder code]: https://github.com/flutter/engine/blob/3.16.0/lib/ui/semantics.dart#L703
[RenderObject]: https://api.flutter.dev/flutter/rendering/RenderObject-class.html
[RendererBinding]: https://api.flutter.dev/flutter/rendering/RendererBinding-mixin.html
[drawFrame]: https://github.com/flutter/flutter/blob/3.16.0/packages/flutter/lib/src/rendering/binding.dart#L590
[flushSemantics]: https://github.com/flutter/flutter/blob/3.16.0/packages/flutter/lib/src/rendering/object.dart#L1259
[sendSemanticsUpdates]: https://api.flutter.dev/flutter/semantics/SemanticsOwner/sendSemanticsUpdate.html
[SBU build]: https://github.com/flutter/engine/blob/3.16.0/lib/ui/semantics.dart#L848
[SemanticsUpdate]: https://github.com/flutter/engine/blob/3.16.0/lib/ui/semantics.dart#L1029
