# Keep your project resilient against CI enshittification

[In my previous post][cirrus ci is the best], I complained that most CI systems
suck, but there's one that doesn't - [Cirrus CI](https://cirrus-ci.org).

**Unfortunately**, as much as I'd like to use Cirrus CI in all projects I work
on, it's not often possible, especially in work settings.

The larger your project is, the harder it gets to migrate your CI. I get that.
After all, most of us gotta ship stuff instead of playing with CI (how
unfortunate).

**Fortunately**, even if you can't migrate off of your current $CI
right now, I have some tips for you how to minimize dependency of your project
on your CI system.

Benefits:
- easier to understand and maintain
- possible to run locally

In my own experience, many Actions aren't well maintained[^1]. Many times I had
to rip out an Action and replace it with a plain old shell script, because the
Action that hasn't been updated in a few years and started crashing.

And since GitHub Actions is in denial of being a package manager, all actions
bundle all the dependencies.

_Another reason is security_, but this is [a whole another topic].

I'd like to share how I approach creating CI pipelines. In general, they could
be summed as "depend on as little vendor-specific features as possible". Treat
CI as dumb compute. Don't try to be smart with it.

This post is skewed towards GitHub Actions, since it's (unfortunately) by far
the most popular one and many open-source projects use it. Most of the tips are
also applicable to other CIs, though.

### Do not use Actions in GitHub Actions

Yes, you read that right. It sounds backward at first, and a bit like a catchy
headline. But I'll stand by it. I basically mean this:

**Think twice before using a new GitHub Action.**

(Or a CircleCI Orb. Whatever.)

The popularity of GitHub Actions is also a huge advantage, with active community
creating custom actions. This is all cool and dandy, until you realize that most
of steps in your workflow are custom Actions, and can't do _anything_ locally.

I prefer to download and call the binary directly. This makes it easier to
migrate off of GitHub Actions later on.

Example 1:

- 👎 https://github.com/1Password/install-cli-action
- 👍 https://github.com/1Password/load-secrets-action

Example 2:

- 👎 base64-decode action
- 👍 $ base64 --decode

### Example: jq and yq

All the uses of various GitHub Actions for installing and using `jq` and `yq`
I've seen could be removed and replaced with calling the binaries directly.

Instead of:

```
steps:
  - name: Set foobar to cool with yq
    uses: mikefarah/yq@v4
    with:
      cmd: yq -i '.foo.bar = "cool"' config.yaml

  - name: Set up jq
    uses: dcarbone/install-jq-action@v2

  - name: Query workspaceId with jq
    run: jq '.target.workspaceId' output.json > workspace_id.txt
```

simply do:

```yaml
steps:
  - name: Set foobar to cool
    run: yq -i '.foo.bar = "cool"' config.yaml
  - name: Query workspaceId with jq
    run: jq '.target.workspaceId' output.json > workspace_id.txt
```

There's often no need to install common tools – they're already included in the
absolutely massive ~50GB Vm image that GitHub Actions uses. [See what's
installed by default on the ubuntu-24.04 runners][ubuntu-runner].

Maybe there are situations when the Action is useful - but only then you should
use the action, not default to it from the start.

### Example: 1Password CLI

### Example: decode base64 to a file

```yaml
steps:
  - name: Run Workflow
    id: write_file
    uses: timheuer/base64-to-file@v1.2
    with:
      fileName: 'myTemporaryFile.txt'
      fileDir: './main/folder/subfolder/'
      encodedString: ${{ secrets.SOME_ENCODED_STRING }}
```

I genuinely don't understand why this Action exists. It's a one-liner in shell:

```shell
echo ${{ secrets.SOME_ENCODED_STRING }} | base64 --decode > ./main/folder/subfolder/myTemporaryFile.txt
```

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

### Write good shell scripts

Shell is an arcane language, full of warts and pitfalls – but it's a
skill just like any other,

Some guidelines that I try to follow when writing shell code:
- use pure `sh` with the `/usr/bin/env sh shebang`, avoid bashisms
- use `set -euo pipefail` [bash strict mode]
- use [shellcheck] and make sure there are no warnings

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

[ubuntu-runner]: https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md
[cirrus ci is the best]: ./cirrus_ci_is_the_best
[a whole another topic]: ./github-actions-supply-chain-security
[shellcheck]: https://www.shellcheck.net
[bash strict mode]: http://redsymbol.net/articles/unofficial-bash-strict-mode

[^1]:
    I want to make clear that I absolutely mean no insult at all to the
    authors who created and published an Action, but don't maintain them because
    of $reasons.
