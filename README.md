# mcp-query-action

> [!WARNING]
> **Deprecated.** This action moved to [`Big-Time-Data/actions/mcp-query`](https://github.com/Big-Time-Data/actions#mcp-query). This repo is archived and gets no more changes. Jobs that use it keep working.
>
> To move, run `mcpq ci add --force`, or change the `uses` line:
>
> ```yaml
> - uses: Big-Time-Data/actions/mcp-query@v1
>   with:
>     version: v0   # the mcpq release: latest, vX.Y.Z, or a major such as v0
>     source: dbt,curated,catalog
> ```

A GitHub Action that builds the MCPQ context and publishes it to your warehouse. It runs the same steps as `mcpq build --publish` on a laptop:

1. Install the `mcpq` release that the tag names, and check its checksum.
2. Write the `MCPQ_CONN` secret to a file.
3. Install uv when `mcpq.yaml` has `generate` for dbt.
4. Build the sources.
5. Post the diff to the step summary.
6. Publish, then run `mcpq validate --stage published`.
7. Run the evals when `eval_tags` is set and `MCPQ_EVAL` holds a key.

## Use

`mcpq ci add --provider github` writes this job. It pins the tag to the `mcpq` release that writes the job.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: big-time-data/mcp-query-action@v0.0.11
    with:
      source: dbt,curated,catalog
      config: mcpq/mcpq.yaml
    env:
      MCPQ_CONN: ${{ secrets.MCPQ_CONN }}
```

## Versions

The tag selects the `mcpq` release:

| Tag | Release |
| --- | --- |
| `@vX.Y.Z` | that release |
| `@v0` | the newest `v0` release |
| `@main` | the newest release |

The `version` input overrides the tag. The releases come from [Big-Time-Data/homebrew-tools](https://github.com/Big-Time-Data/homebrew-tools/releases).

## Inputs

| Input | Default | Meaning |
| --- | --- | --- |
| `source` | all enabled | Comma-separated source names |
| `config` | `./mcpq.yaml`, else `./mcpq/mcpq.yaml` | Path to `mcpq.yaml`, from `working_directory` |
| `working_directory` | `.` | Folder to run `mcpq` in |
| `version` | from the tag | `latest`, `vX.Y.Z`, or a major such as `v0` |
| `eval_tags` | empty | Eval tags to run after publish; empty skips the evals |
| `github_token` | empty | Token for the GitHub API call that finds a major version |
| `bin` | empty | Path to an `mcpq` binary, for tests of the action |

## Secrets

- `MCPQ_CONN`: the content of the conn file, or a path to it. The action fails when it is not set.
- `MCPQ_EVAL`: optional. The API key of the eval harness.

## Changes to this repo

Each `mcpq` release copies `action.yml` and `scripts/install.sh` into this repo, and tags the release and its major version. Do not edit the two files here: the next release replaces them. The `test` workflow runs the action against Postgres.
