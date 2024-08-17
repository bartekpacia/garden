---
date: 20240816
title: Cirrus CI is the best CI system out there
description: And nothing comes even close.
image: /assets/cirrus-ci-is-the-best/change-my-mind.png
---

# Cirrus CI is the best CI system out there

![](assets/cirrus-ci-is-the-best/change-my-mind.png)

> **Disclaimer**
> 
> I'm in no way affiliated with Cirrus CI, apart from submitting a few PRs to
> their repos. I'm just genuinely amazed at how _good_ it is.

### A rant-ish intro

I'm a fan of CI. I love seeing green check next to my PRs. The thing is,
**"modern" CI systems mostly suck**.

Travis CI commoditized CI but has been enshittified to the ground[^1]. The vast
majority of open-source software has since moved to GitHub Actions, and it seems
like it's here to stay for longer. Unlimited minutes are too good to ignore,
right?

It's becoming indispensable. But think about this: how much longer will
Microsoft want to pay for running CI for millions of projects out there? I'm
pretty sure they'll stop it at some point, and actually start milking money out
of us. What else would they try to capture so much market share?

GitHub Actions also [has shaky fundamentals][gha feels bad] and lots of strange
behaviors. I mean, just go watch [this great video by
fasterthanlime](https://youtu.be/9qljpi5jiMQ?si=-Ouh91gt7NjCkdZQ) (it's both
scary and very funny).

I will try to convince you that Cirrus CI is _objectively_ better than every
other major CI system in existence: GitHub Actions, CircleCI, GitLab CI/CD, and
Buildkite.

## Why is Cirrus CI the best

(These are the reasons that matter to me. I might've forgotten about some)

### Local execution support

The nemesis of GitHub Actions, GitLab CI/CD, CircleCI, and honestly, pretty much
everything else. And no, [nektos/act] isn't good enough.

How did it happen that in 2024 we still cannot easily run CI pipelines locally?
We send our jobs to the master in the cloud and pray for the green checkmark.

Cirrus CI provides the AGPL-licensed [Cirrus CLI tool][cirrus cli], a static
binary written in Go. Just `brew install cirruslabs/cli/cirrus` and you can run
your CI jobs locally:

```console
cirrus run test
```

will run the task `test` in a fresh Docker container:

```yaml
task:
  name: test
  container:
    image: azul/zulu-openjdk-alpine:21
  lint_script: ./gradlew detekt
  test_script: ./gradlew test
```

> I'm not going to explain the [YAML config format of Cirrus CI][cirrus yaml],
> it's not the focus of this post. It's very similar to GitHub Actions or Circle
> CI.

Or maybe (assuming you're on macOS) you want to run a macOS VM? No problem!

```yaml
test_macos_task:
  name: Run `maestro test` on macOS
  macos_instance:
    image: ghcr.io/cirruslabs/macos-sonoma-xcode:latest
```

This uses [Tart] - a source-available, very convenient wrapper around [Apple's
Virtualization.framework][apple virt]. Guess what, it's also created by Cirrus
CI.

### Persistent workers

What if you don't want to run your CI jobs in the cloud, but on your own
hardware? Maybe, I don't know, your job is actually cool and you do some
embedded development, you have a server that's connected to some MCUs in your
space lab, and you'd like to run tests on it whenever you push to a branch.

Cirrus CI lets you create a [persistent worker] to do just that! Really, it
doesn't get any easier. If your use-case is exotic (and you understand the
tradeoffs), you can even choose to not spawn a new Docker container for every
task run, but run directly the server, to not install dependencies for the
1000th time.

This single feature seems similar to the entire premise of
[Buildkite](https://buildkite.com) – run agents on your own infra. In Cirrus CI,
it's just another feature!

### Open-source

Rest assured, I'm not here with another idealistic "big corp bad, do the right
thing, use only open-source, hurr durr" rant.

The thing is, being open-source is an actual feature. I can look into the Cirrus
CLI or Cirrus Agent code. I can [fix things that annoy me][my cirrus ci pr].

It's also very interesting from the educational standpoint. I like peeking under
the hood of things.

In addition to Cirrus CLI being open-source, Cirrus CI actively innovates in the
tooling space by creating source-available tools like [Tart], [Vetu], and
[Orchard]. Those are impressive tools on their own, but integrate very well with
Cirrus CI.

### Config that scales

Sooner or later CI configuration becomes an incomprehensible mess of duplicated
YAML. There are [different approaches to solve that][github reusing workflows],
but Cirrus CI does the best job here again.

In addition to YAML, we can also define our jobs in [Starlark] – a tiny,
deterministic language that's similar (both in syntax and semantics) to Python.
Starlark code for Cirrus is written in the `.cirrus.star` file in the repo root.
[Here are docs for programming Cirrus tasks in
Starlark](https://cirrus-ci.org/guide/programming-tasks).

Let's say you have 10 tasks that all run the same `apt-get install` as their
first step? Easy – simply extract those calls to a function and put it in some
`common.star` file:

```python
# common.star

def install_stuff():
    return script(
        "install_stuff",
        "apt-get install bar",
        'apt-get install whatever-you-want',
    )
```

and then  call that function 10 times, just like you'd do in normal code:

```python
# .cirrus.star

load("common.star", install_stuff) # import our common utils

def main():
  pubspec = fs.read("pubspec.yaml")
  flutter_version = yaml.loads(pubspec)["environment"]["flutter"]

  return [
    task(
      name = "Run thingies",
      instance = container(image = "node:22-alpine.3.19"),
      instructions = [
        install_stuff(),
        # ...
      ],
    ),
  ]
```


> Or better even - instead of installing it 10 times, create a Dockerfile and
> install the dependencies there. Cirrus CI will automatically build an image,
> cache it, and use it for subsequent runs ([see docs][cirrus dockerfile]). How
> cool is that!

With Starlark, you can also generate the CI pipeline code dynamically. Here's an
example that uses the Flutter version directly from `pubspec.yaml`
(`package.json` but in Flutter world), and uses that to pull the matching OCI
image:

```python
# .cirrus.star

load("cirrus", "fs", "yaml")

def main():
  pubspec = fs.read("pubspec.yaml")
  flutter_version = yaml.loads(pubspec)["environment"]["flutter"]

  return [
    task(
      name = "Build Android app",
      alias = "build_andrid",
      instance = container(
        image = "ghcr.io/cirruslabs/flutter:%s" % flutter_version,
      ),
      instructions = [
        cache("pub", "~/.pub-cache"),
        script("flutter", "build", "apk"),
        # ...
      ],
    ),
  ]
```

This is a very efficient and pleasant approach to generating workflows
dynamically. No more YAML!

And if this wasn't impressive enough, Cirrus CI config can be locally
[validated](https://github.com/cirruslabs/cirrus-cli/blob/6faa293cd395980359764aaec3b8821b3c606221/README.md#validating-cirrus-configuration)
and
[tested](https://github.com/cirruslabs/cirrus-cli/blob/v0.122.2/STARLARK-MODULES.md#testing)
– which brings us to the next point.

### Config validation and testing

How many times did you `git push` only to see this

![](assets/cirrus-ci-is-the-best/gha syntax error.png)

Sure, now there's a GitHub Actions extension for VSCode that makes makes it
easier to write correct workflows thanks to its integration with JSON schema.
But it's only in VSCode.

Want to validate that your Cirrus CI files (both in YAML and in Starlark) don't
contain syntactic (and some semantics) errors?

```console
cirrus validate
```

Why no other CI does this? So simple, so useful.

### Simple and modern

Cirrus CI is actually well thought of and simple (see [Life of a Build][cirrus
is simple]). They don't maintain their own server fleet – instead they run your
tasks on public clouds like GCP, AWS, and Azure.

No magic. It's all OCI all the way down!

You may think that GitHub Actions is also simple and obvious - [it is not][gha
feels bad][^2]. Don't look under the hood if you want to feel good about using
it.

### Flexible

If you didn't already realize that, Cirrus CI is very flexible. Linux container?
Linux Arm container? MacOS VM? FreeBSD VM? Your own OCI-compatible Linux
container or macOS VM image, running on your own infra? Check.

It even supports [Windows Containers] - a thing I didn't know exists (and which
I've never used).

I don't know what else you might want.

## What to be aware of

Nothing is perfect, and neither is Cirrus CI – but it definitely does come the
closest to some "Continuous Integration singularity".

- The web console UI is very basic, but honestly, I don't care at all – it does
  the job. 

  ![Come on, it's CI, it doesn't have to be
  pretty](assets/cirrus-ci-is-the-best/cirrus screenshot.png)

- It's not completely free for open-source, like GitHub Actions. The free plan
  is generous though - 10 000 CPU-minutes for Linux tasks or 500 minutes for
  macOS tasks (which always use 4 CPUs). [See pricing][cirrus ci pricing].

- For private personal repos, it costs $10/month (though I think it's a very
  fair price). For private org repos, it's $10/seat/month.

- It integrates only with GitHub.

- Low bus factor of the company (/s), which leads us to...

## Who's behind it?

From what I see on Cirrus' GitHub repos, it's built by literally 2 guys – [Fedor
Korotkov](https://github.com/fkorotkov), a former Airbnb and JetBrains employee,
and [Nikolay Edigaryev](https://github.com/edigaryev).

Those two are single-handedly revolutionizing the CI space.

The sad thing to me is that Cirrus CI isn't more popular. So many people accept
the (arguably pretty shitty) status quo of CI. It can be so much better, and
Cirrus CI shows it's possible.

### Further reading

- I'm mentioning it the 3rd time now, but it's really worth it: [go watch GitHub
  Actions feels bad][gha feels bad], you will not regret!
- [Introducing Cirrus
  CI](https://medium.com/cirruslabs/introducing-cirrus-ci-a75cd1f49af0)
- [Cirrus CI stack](https://medium.com/cirruslabs/cirrus-ci-stack-8a38aa4576d6)
- [Core principle of Continuous Integration systems is
  obsolete](https://medium.com/cirruslabs/core-principle-of-continuous-integration-systems-is-obsolete-8d926e17c721)

### Summing up

It truly is amazing what a small team can accomplish by focusing on a problem
and just solving it, the right way. Cirrus CI completely out-executed major
players like Microsoft, GitLab, and CircleCI.

I encourage everyone angry at their CI to give Cirrus CI a try. It's truly a
breath of fresh air.

[^1]: Travis CI got so bad that even though I have unlimited minutes from GitHub
    Student Developer Pack, I don't use it at all. I mean, look: I, a student,
    don't use something that's free. It says something, lol.
[^2]: I really do recommend watching this video. It's just freaking awesome.

[nektos/act]: https://github.com/nektos/act
[gha feels bad]: https://youtu.be/9qljpi5jiMQ
[cirrus yaml]: https://cirrus-ci.org/guide/writing-tasks
[cirrus cli]: https://github.com/cirruslabs/cirrus-cli
[Tart]: https://github.com/cirruslabs/tart
[Starlark]: https://github.com/bazelbuild/starlark
[Orchard]: https://github.com/cirruslabs/orchard
[Vetu]: https://github.com/cirruslabs/vetu
[my cirrus ci pr]: https://github.com/cirruslabs/cirrus-cli/pull/716
[persistent worker]: https://cirrus-ci.org/guide/persistent-workers
[apple virt]: https://developer.apple.com/documentation/virtualization
[github reusing workflows]:
    https://docs.github.com/en/actions/sharing-automations/reusing-workflows
[cirrus ci pricing]: https://cirrus-ci.org/pricing
[cirrus dockerfile]:
    https://cirrus-ci.org/guide/docker-builder-vm/#dockerfile-as-a-ci-environment
[cirrus is simple]: https://cirrus-ci.org/guide/build-life
[windows containers]:
    https://cirrus-ci.org/guide/supported-computing-services/#windows-support
