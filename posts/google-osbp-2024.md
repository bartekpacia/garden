---
date: 20240625
title: I was awarded Google Open Source Peer Bonus
description: It ain't much, but it's honest work.
image: assets/google-ospb-2024/it_aint_much_2.jpg
---

# I was awarded Google Open Source Peer Bonus

A bit late, but I'm happy to share that I was awarded Open Source Peer Bonus – a
Google initiative that recognizes people who contributed to open-source
projects.

![](assets/google-ospb-2024/email.avif)

# Some backstory

My journey with contributing to Flutter started with me working at LeanCode on
the [Patrol](https://github.com/leancodepl/patrol) project. Because we had to do
things that no one had done before in Flutter ecosystem[^1], we naturally
discovered a lot of problems (both in Flutter itself and the tools surrounding
it) – and I always strived to report every single one of them[^2]. After a few
months, I realized I had created a few dozen issues.

Somewhere around that time (that is, end of 2022), I also got pretty interested
in build systems, and specifically, in Gradle (don't ask me why, it just
happened). I think I read its docs a few times during the winter break, and
really liked it.

I then noticed some Gradle warnings whenever I was running `flutter build apk`.
It was a minor warning, something related to using deprecated Gradle features
that would be removed in the subsequent major release. I had seen them countless
times before and they never made sense to me – but now, armed with knowledge of
Gradle, I understood what was happening and [went on to fix it].

I then started reading Gradle source code inside Flutter repo [the gigantic
`flutter.gradle` file][gradlefile], understanding how it works, and fixing more
and more small problems, deprecations, etc. In the beginning it sure wasn't
much, but it was honest work.

# What I did

During the last year, I made various contributions across 3 repositories in the
Flutter org (click on the links to see them):

- [flutter/flutter](https://github.com/flutter/flutter/issues?q=author%3Abartekpacia+)
- [flutter/engine](https://github.com/flutter/engine/pulls?q=author%3Abartekpacia)
- [flutter/website](https://github.com/flutter/website/issues?q=author%3Abartekpacia)

Many of them are small-ish. The ones worth highlighting are related to improving
Flutter's Android support to use modern Gradle practices:

- [Refactor Flutter Gradle Plugin so it can be applied using the declarative plugins {} block #123511](https://github.com/flutter/flutter/pull/123511)
- [Refactor "app plugin loader" Gradle Plugin so it can be applied using the declarative plugins {} block #127897](https://github.com/flutter/flutter/pull/127897)
- [Add support for Gradle Kotlin DSL #140744](https://github.com/flutter/flutter/pull/140744)

My most impactful (and most technically complex) contribution was fixing this
issue:

- [Missing accessibility-id for testing purposes #17988](https://github.com/flutter/flutter/issues/17988)

It was the most-upvoted-ever testing-related issue in the Flutter repo, opened
since 2018, with ~130 likes.

Truth be told, it's the only contribution I was paid for – and I'm thankful to
[mobile.dev](https://www.mobile.dev), the company that did that. To learn more
about what the problem was, and how I approached solving it, [read the blogpost](https://blog.mobile.dev/the-power-of-open-source-making-maestro-work-better-with-flutter-d92b386f9a33).

# How it feels

It feels great!

I hadn't been aware of existence of OSPB until I received it (which,
coincidentally, happened the day after my birthday), so it was certainly a very
pleasant surprise.

There's also some monetary award associated with it, and even if it's not that
much (a few hundred dollars), it means a lot to me. It's still by far the
largest amount of money I've made off of contributing to open-source.

Thanks a lot, Google, for supporting open-source contributors - and of course,
Google consists of people, therefore I want to thank Reid Baker for the
nomination, and the whole Flutter team for making the project so incredibly
welcoming to external contributors and putting so much trust in their hands.

[^1]: The aim was to built much better testing capabilities than what was
    available at the time. Hard problems included interacting with native UI
    (even of other apps) from withing Dart test code, and ensuring isolation
    between tests. If you'd like to learn more, check out [the talk] I gave with
    my tech lead at the time.

[^2]: I think that before anyone complains about any open-source project on some
  so-called social media website, they should first make sure the issue is
  reported, and if it's not, they should report it. In my book, only then you
  get a license to complain. And if you complain, link to the issue, so people
  can at least give thumbs-up.

[gradlefile]: https://github.com/flutter/flutter/blob/3.10.0/packages/flutter_tools/gradle/flutter.gradle
[the talk]: https://youtu.be/WJKcZ5ob718
[went on to fix it]: https://github.com/flutter/flutter/pull/122290
