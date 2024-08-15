---
date: 20240815
title: Cirrus CI is the best
description: And nothing comes even close.
image: assets/cirrus_ci_is_the_best/change my mind.png
---

# Cirrus CI is the best CI system out there

![A man sitting behind a table with "Change my mind" poster][assets/cirrus_ci_is_the_best/change my mind.png]

### Intro

I'm a fan of CI. I love seeing green check next to my PRs. The thing is,
**"modern" CI systems mostly suck**.

- Travis CI commoditized CI but has been enshittified. The vast majority of
  open-source software moved to GitHub Actions.

- The popularity of GitHub Actions is its biggest advantage, but also its curse.
  It's indispensable. I mean, how much longer will Microsoft want to pay for
  running CI for millions of projects out there? I'm pretty sure they'll stop it
  at some point, and actually start milking money out of us.

- GitHub Actions is [has shaky fundamentals]. I mean, just go watch [this great
  video by fasterthanlime](https://youtu.be/9qljpi5jiMQ?si=-Ouh91gt7NjCkdZQ)

I will try to convince you that Cirrus CI is _objectively_ better than every
other major CI system in existence: GitHub Actions, CircleCI. I haven't used
Buildkite much, though it bears some similarities to Cirrus CI.

## Why is Cirrus CI the best

It has so many killer features.

### Local execution support

The nemesis of GitHub Actions. And no, [nektos/act] isn't good enough.

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
    image: openjdk:21
  lint_script: ./gradlew detekt
  test_script: ./gradlew test
```

> I'm not going to explain the [YAML config format of Cirrus CI][cirrus yaml],
> it's not the focus of this post. It's very similar to GitHub Actions or Circle
> CI.

Or maybe (assuming you're on macOS) you want to run a macOS VM? No problem!

```yaml
test_macos_task:
  name: Test `patrol develop` on macOS
  macos_instance:
    image: ghcr.io/cirruslabs/macos-sonoma-xcode:latest
```

This uses [Tart] - a source-available, very convenient wrapper around [Apple's
Virtualization.framework][apple virt]. Guess what, it's also created by Cirrus
CI.

### Persistent workers

What if you don't want to run your CI jobs in the cloud, but on your own
hardware? Maybe, I don't know, you're doing some embedded development and you
have a server that's connected to some MCUs in your space lab, and you'd like to
run tests on it whenever you push to a branch.

Cirrus Ci lets you create a [persistent worker] to do just that! Really, it
doesn't get any easier. If your use-case is exotic (and you understand the
tradeoffs), you can even choose to not spawn a new Docker container for every
task run, but run directly the server, to not install dependencies for the
1000th time.

This single feature seems similar to the entire premise of
[Buildkite](https://buildkite.com) – run agents on your own infra. In Cirrus CI,
it's just another feature!

### Open-source

Rest assured, I'm not here with another idealistic "big corp bad, do the right
thing, use only open-source, hurr durr" rant. The thing is, being open-source is
an actual feature. I can look into the Cirrus CLI or Cirrus Agent code. I can
[fix things that annoy me][my cirrus ci pr]. It's even interesting from the
educational standpoint. I like peeking under the hood of things.

- Very flexible (Linux container? Linux Arm container? MacOS VM? FreeBSD VM?
  Everything!). Your own OCI-compatible image? Check. Running in own
  infrastructure? Also works.
- Open source and open in general. It's all OCI containers!
- Creates many great source-available projects. Cirrus the company has created
  incredible tools like Tart, and more are stabilizing – Orchard, Vetu.
- Workflows can be EXECUTED locally with Cirrus CLI
  - Workflows can be VALIDATED locally ($ cirrus validate)
  - Workflows can be TESTED locally! ($ cirrus internal test)

### Configuration that scales

Sooner or later CI configuration becomes an incomprehensible mess of duplicated
YAML. There are [different approaches to solve that][github reusing workflows],
but Cirrus CI does the best job here again.

In addition to YAML, we can also define our jobs in [Starlark] (which generates
YAML) – a tiny, deterministic language that's similar (both in syntax in
semantics) to Python.

You have 10 tasks that all run the same `apt-get install` as their first step?

This is a very efficient and pleasant approach to generating workflows
dynamically. No more YAML!

> Or better even - instead of installing it 10 times, create a Dockerfile and
> install the dependencies there. Cirrus CI will automatically build an image,
> cache it, and use it for subsequent runs ([see docs][cirrus dockerfile]). How
> cool is that!

### Configuration that can be validated locally

How many times did you `git push` only to see this

![github actions syntax error][assets/cirrus_ci_is_the_best/gha syntax error.png]

Sure, now there's a GitHub Actions extension for VSCode that makes makes it
easier to write correct workflows thanks to its integration with JSON schema.
But it's only in VSCode.

Want to validate that your Cirrus CI files (both in YAML and in Starlark) don't
contain syntactic (and some semantics) errors?

```console
cirrus validate
```

Why no other CI does this? So simple, so useful.

### Simple

Cirrus CI is actually well thought of and simple – see [Life of a Build][cirrus
is simple].

You may think that GitHub Actions is also simple and obvious - [it is not][gha
feels bad][^1].


## What to be aware of

Nothing is perfect, and neither is Cirrus CI – but it definitely does come the
closest to some "Continuous Integration singularity".

- The web console UI is very basic, but honestly, I don't care at all – it does
  the job. Come on, it's CI, it doesn't have to be pretty.

- It's not completely free for open-source, like GitHub Actions. The free plan
  is generous though - 10 000 CPU-minutes for Linux tasks or 500 minutes for
  macOS tasks (which always use 4 CPUs). [See pricing][cirrus ci pricing].

- For personal repos, it costs $10/month (though I think it's a very fair
  price).

- It integrates only with GitHub.

### Summing up

It truly is amazing what a small, focused team can accomplish by focusing on a
problem and just solving it, the right way. They totally out-executed major
players like Microsoft and Circle CI.

I encourage everyone angry at their CI to give Cirrus CI a try. It's truly a
breath of fresh air.

[^1]: I really do recommend watching this video. It's just freaking awesome.

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
[github reusing workflows]: https://docs.github.com/en/actions/sharing-automations/reusing-workflows
[cirrus ci pricing]: https://cirrus-ci.org/pricing
[cirrus dockerfile]: https://cirrus-ci.org/guide/docker-builder-vm/#dockerfile-as-a-ci-environment
[cirrus is simple]: https://cirrus-ci.org/guide/build-life
