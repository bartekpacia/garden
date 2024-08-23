# Keep your project resilient against CI enshittification

Modern CI mostly suck.

The larger your project is, the harder it gets to migrate your CI. I get that.
After all, most of us gotta ship stuff instead of playing with CI (how
unfortunate).

Even if you can't/don't want to migrate off of your current $CI right now, I
have some tips for you how to minimize dependency of your project on your CI
system.

I'd like to share how I approach creating CI pipelines. In general, they could
be summed as "depend on as little vendor-specific features as possible". Treat
CI as dumb compute. Don't try to be smart with it.

This post is skewed towards GitHub Actions, since it's by far the most popular
(unfortunately) and many open-source projects use it, but the tips should be
applicable to most contemporary CI platforms like Circle CI.

### Do not use Actions in GitHub Actions

Yes, you read that right. It sounds backward at first, and it indeed is a catchy
headline. I basically mean this:

**Think twice before using an Action.**

(Or an Orb. Whatever)

The popularity of GitHub Actions is also a huge advantage, with active community
creating custom actions. This is all cool and dandy, until you realize you've
offloaded all of your CI to GitHub, and can't do _anything_ locally.

Prefer to download and call the binary directly. This makes it easier to migrate
off of GitHub Actions later on.

Example 1:

- 👎 https://github.com/1Password/install-cli-action
- 👍 https://github.com/1Password/load-secrets-action

Example 2:

- 👎 base64-decode action
- 👍 $ base64 --decode

In my own experience, many Actions aren't well maintained[^1]. Many times I had
to rip out an Action that hasn't been updated in a few years.

And since GitHub Actions is in denial of being a package manager, all actions
bundle all the dependencies.

_Another reason is security_, but this is [a whole another topic].

### Do not paste secrets directly.

If you need to paste 37 secrets for 21 different services and devtools just to
give your CI pipeline _a chance_ of passing, you're doing it wrong. You
willfully increase the cost of adopting any other CI platform when the current
one will undoubtedly enter the path of enshittification (which is bound to
happen, sooner or later).

My preferred solution to this is 1Password Service Accounts.

### Infer as much config as possible

I've witnessed many projects needlessly duplicate configuration in CI:

- Java version both in `build.gradle.kts` and in workflow file
- Go version both in `go.mod` and in workflow file
- Flutter version both in `pubspec.yaml` and in workflow file

Sometimes it's even worse - versions are duplicated across many workflow files.
It's easy to forget about the need to update the duplicated versions in CI.

Let's look at the Go example. A common pattern is this:

```yaml
jobs:
  main:
    ...
    steps:
      - name: Clone repository
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
```

### Keep shell scripts out of YAML

I don't have a hard rule as to length, but the more lines of shell script
there's in YAML, the more unease I feel.

Actually, after a few years of actively using GHA, I stand by the opinion that
CI should only call shell scripts. Shell code directly in CI config is a huge
code smell. That shell code is locked there. You can't even shellcheck it.

If the shell script becomes too long, extract it into an executable file and
just execute it from within the CI workflow.

This way you can run `shellcheck` and `shfmt` on the shell scripts. I can't
stress enough how great these 2 tools are. Use them.

Use the correct shebang in the shell script file. Remember that bash != sh. If
possible, stick to POSIX sh compatibility (although that's my personal
zboczenie).

### Format it

Tools like `gofmt`, `rustfmt`, and `prettier` are popular in their respective
programming language ecosystems because they make for you decisions that don't
matter - formatting. There's a high chance your CI workflow is written in YAML -
if so, run `prettier` on it (and check). It'll make it easier to read for
everyone.

Here's a one liner to format all `yaml` files in the `.github` directory:

```console
prettier --write .github/**/*.yaml
```

If possible, use default prettier style - the less config, the better.

[^1]:
    I want to make clear that I absolutely mean no insult at all to the
    authors who created and published an Action, but don't maintain them because
    of $reasons.
