# Web Deployment

Draft Dash includes a Flutter web runner plus Cloudflare Pages-compatible SPA
fallback and response headers. No deployment happens in normal CI.

## Recommended Greenbean Setup

Use a dedicated Cloudflare Pages **Direct Upload** project at
`draft.greenbean.studio`. The manual `Deploy web` GitHub Actions workflow:

1. installs the pinned Flutter 3.41.9 toolchain;
2. builds and verifies the repository in GitHub Actions; and
3. uploads the prebuilt `build/web` directory with Wrangler.

Configure the protected GitHub environment `greenbean-studio` with:

- secret `CLOUDFLARE_API_TOKEN`: a scoped token allowed to deploy Pages;
- secret `CLOUDFLARE_ACCOUNT_ID`: the owning Cloudflare account ID; and
- secret `CLOUDFLARE_PAGES_PROJECT`: the existing Direct Upload Pages project
  name.

Create the Pages project and attach its custom hostname in Cloudflare before
running the workflow. Do not connect that project to Cloudflare's Git build
integration. Production is built from a clean checkout and uploaded only by the
manual (`workflow_dispatch`), main-branch-only workflow, so merging a change
cannot publish it unexpectedly. GitHub Actions supplies the pinned Flutter
toolchain and is the supported production build environment.

The repository's regular CI may compile web bundles to catch regressions, but
those artifacts are never deployed. The production artifact is always rebuilt
inside the manual deployment job immediately before Direct Upload.

## Root or Subdomain Contract

Build a project that owns its whole hostname with:

```bash
./tool/build_web.sh
```

Publish `build/web`. It contains the root fallback:

```text
/* /index.html 200
```

That contract is appropriate for a dedicated hostname such as
`draft.greenbean.studio`, or for `greenbean.studio` only if Draft Dash owns the
entire root site.

## Existing Site `/draft/` Contract

If another project already owns `greenbean.studio`, build a mergeable path
fragment instead:

```bash
./tool/build_web.sh --mount-path /draft/
```

The output is `build/site`, with the Flutter bundle under `build/site/draft/`
and Cloudflare control files at `build/site/_headers` and
`build/site/_redirects`. The generated SPA fallback is:

```text
/draft/* /draft/index.html 200
```

The root site's pipeline must merge `build/site/draft/` into its own output and
merge the generated `_headers` and `_redirects` rules into its root control
files. Do not Direct Upload `build/site` to the root site's Pages project by
itself and never replace the root project's published directory with this
fragment: a Pages deployment replaces that project's complete asset set.

An alternative reverse proxy may strip `/draft/` and proxy to the dedicated
Pages hostname. In that design, the upstream bundle must be built for the public
`/draft/` base path, while the proxy must forward all `/draft/*` assets and
history-fallback requests consistently. The merge contract above is simpler
and is the supported path-mount baseline in this repository.

## Routing Scope

The web app uses Flutter's path URL strategy. Cloudflare returns the matching
`index.html` for direct visits to clean routes such as `/setup` or
`/draft/setup`. The catch-all header rule also forces those app-shell responses
to revalidate, so a release cannot leave a clean route serving a stale shell.

These web routes are not native Universal Links or Android App Links. Native
links additionally require application entitlements/intent filters and hosted
Apple `apple-app-site-association` and Android `assetlinks.json` association
files. That native association setup is not included in this foundation.

## Reproducible Shared Dependency

`progenitor_core` is fetched from its public GitHub repository at a pinned commit
instead of the former `../progenitor` path. This makes a fresh clone and GitHub
Actions self-contained without copying code from a sibling worktree. Dependabot
will not advance this pin automatically; update the commit deliberately and run
the full validation suite when adopting upstream changes.

## Local Verification

```bash
flutter pub get
flutter analyze
flutter test
./tool/build_web.sh
```

Serve the chosen output through HTTP when manually checking navigation; opening
`index.html` directly from disk does not model browser routing correctly.
