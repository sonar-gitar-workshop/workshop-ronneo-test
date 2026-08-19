# Gitar workshop

This will walk you through setting up [Gitar](https://gitar.ai), opening a few different PR's, and watch an AI code reviewer find bugs, enforce your project's conventions, and fix a broken CI pipeline (all of which happens in the browser, no need to hop into any code editors).

This guide works as a live reference during the workshop and as a standalone walkthrough afterward.

## Prerequisites

- A GitHub account that can create the workshop repository, open pull requests, and install a GitHub App
- Admin access to at least one GitHub organization

No local tools or CLI are required for this, you can just install Gitar as a GitHub App.

## Part 1: Install Gitar

### Create your repo

1. Go to the template repository (your presenter will share the link).
2. Click **Use this template** > **Create a new repository**.
3. Check **Include all branches** before you create the repo. The workshop uses three branches that contain pre-staged code changes, so if you ship this checkbox then the branches won't be there when you need them.
4. Set the owner to your personal account and give the repo any name you like.
5. Click **Create repository**.

### Install the Gitar GitHub App

1. Go to [gitar.ai](https://gitar.ai) and click **Install Now**.
2. Select **Only select repositories** and choose the repository you just created.
3. Complete the installation.

### Verify

Go to your repository's **Settings** > **GitHub Apps** (under Integrations). You should see Gitar listed, so if it appears, you're ready for Part 2.

If Gitar does not appear after a minute, refresh the settings page. Sometimes GitHub takes a moment to reflect newly installed apps. If it still doesn't appear, try the install again from [gitar.ai](https://gitar.ai), because a common cause is selecting the wrong repository or the wrong GitHub account during installation.

## Part 2: Gitar finds and fixes a business logic bug

### Open the pull request

1. In your repository, go to **Pull Requests** > **New pull request**.
2. Set **base** to `main` and **compare** to `part-2-price-override`.
3. Click **Create pull request**. You can leave the title and description as they are.

### Wait for the review

Gitar reviews the pull request automatically. In previous runs of this step, the review appeared in about ~30 seconds, and the dashboard comment appears a little after that.

You should see a review comment from Gitar with a **Security** finding tagged with a red alert icon. The finding explains that the code change lets API clients set their own price for products, which means anyone could buy a $25 item for a penny. Gitar caught this because the code contradicts a comment in the source that says catalog prices are authoritative, and an endpoint that accepts client-supplied prices violates that invariant.

The PR also shows a blocking review status, which means Gitar would prevent this from merging in its current state.

If no review appears after a few minutes, confirm that you installed Gitar for the repository you created, then check the Gitar dashboard for the review status.

### Ask Gitar to fix it

Comment on the pull request:

```
gitar fix this
```

The fix should remove the client-supplied price path entirely and always uses the server-side catalog price, which is the correct behavior. After the fix, Gitar updates its review to **Approved** and the CI checks pass.

Scroll through the review to see the before-and-after. The finding moves from unresolved to resolved, and the blocking status clears.

### Recap

You opened a pull request with a one-line code change that was intended to look fine (the PR title even says "Support cached unit prices from mobile clients"), and Gitar identified it as a security problem by reasoning about what the code should do based on the repository's own context. Then Gitar was askjed to fix it, and it pushed a commit that resolved the issue.

## Part 3: Gitar enforces project conventions

### Open the pull request

1. **Pull Requests** > **New pull request**.
2. Set **base** to `main` and **compare** to `part-3-context-ingestion`.
3. Click **Create pull request**.

### Wait for the review

This PR includes three changes: a new line of application code, a review instruction file in `.gitar/review/instructions.md`, and a repository rule in `.gitar/rules/order-api-change-check.md`. Gitar reads the instruction and rule files from the PR's branch, so they take effect on this review even though they don't exist on `main` yet.

Roughly the following should appear (below output is from previous runs, but exact findings can vary slightly):

**A blocking code review finding.** The finding is tagged as a **Quality** issue and says the order reference does not follow the `ORDER-000001` format. The code uses `order-1` (lowercase, unpadded), while the project convention defined in the instruction file requires an uppercase `ORDER-` prefix with the numeric ID zero-padded to six digits. Gitar cites the project convention by name in the finding, because this isn't a generic best-practice suggestion but an enforcement of a rule that exists only in your repository's configuration.

**A separate rule action comment.** Below the code review, Gitar posts a comment requesting API documentation updates because the rule detected a new field in the public order response. The review summary also shows a "Rules" section with "1 action taken" and a guitar emoji, which is how Gitar distinguishes rule actions from code review findings.

If the review does not appear after a few minutes, confirm that Gitar can access the repository, then check the Gitar dashboard for the review status.

### Building on concepts

In Part 2, Gitar caught a bug using its general understanding of the code. Here, it's enforcing a convention specific to this project, one it could only know about because of the instruction file you added to the repository. The rule action works differently so instead of analyzing code quality, it watches for specific PR events (in this case, changes to `app.py`) and runs an automated workflow.

Review instructions and repository rules are what make Gitar's reviews project-aware rather than generic.

## Part 4: Gitar fixes a failing CI pipeline

### Open the pull request

1. **Pull Requests** > **New pull request**.
2. Set **base** to `main` and **compare** to `part-3-ci-failure`.
3. Click **Create pull request**.

### Watch CI fail

GitHub Actions runs the test suite automatically when you open the PR. One test fails because the code change altered the response status for unknown products, and the test still expects the original behavior.

Gitar detects the CI failure automatically and posts an analysis comment that identifies the failing test, explains the root cause (the test expects a 404 but the code now returns a 200), and recommends a fix. Gitar also posts a code review with its own findings about the change. All of this happens without any action from you.

### Ask Gitar to fix it

Comment on the pull request:

```
gitar fix CI
```

Gitar pushes a fix commit that restores the correct behavior (returning a 404 for unknown products). GitHub Actions reruns automatically after the push. Once CI is green, Gitar updates its review to **Approved**.

If CI doesn't rerun after Gitar's fix commit, push an empty commit to trigger it:

```bash
git commit --allow-empty -m "trigger CI" && git push
```

Or, since everything in this workshop happens in the browser, you can edit any file on the branch through GitHub's web editor (add a blank line to the README, for example) and commit the change to trigger CI.

### The fix

Gitar read the CI logs, identified which test was broken and why, and waited for you to decide what to do about it. When you said `gitar fix CI`, it pushed a commit that fixed the underlying code problem (not the test assertion), because the original 404 behavior was correct and the PR's change was the bug. CI reran and went green without any manual intervention beyond the fix command.

## Take-home

The workshop covered code review with fix suggestions, project-specific review instructions and rules, and CI failure diagnosis with automated fixes.

The easiest next step is to try Gitar on one of your own repositories. Install it from [gitar.ai](https://gitar.ai), select a repository, and open a pull request. Gitar reviews it automatically with no configuration required. The 14-day trial includes Pro features, so you can try review instructions and rules on your own codebase.

From there, create a `.gitar/review/instructions.md` file that describes your project's conventions, coding standards, or architectural rules. Gitar reads these on every review and enforces them alongside its standard analysis. If you manage multiple repositories, Gitar also supports organization-wide custom instructions through the [Gitar dashboard](https://docs.gitar.ai/configuration/settings), and individual repositories can layer additional conventions on top.

Gitar integrates with [Jira](https://docs.gitar.ai/integrations/jira), [Linear](https://docs.gitar.ai/integrations/linear), and [Slack](https://docs.gitar.ai/integrations/slack) so that review context includes linked ticket details and notifications go where your team already works.

## Troubleshooting

**Gitar doesn't appear in Settings > GitHub Apps.** Refresh the page and wait a minute. If it still doesn't show, go back to [gitar.ai](https://gitar.ai) and click Install Now again. The most common causes are selecting the wrong repository during installation, choosing an organization account instead of your personal account, or the browser caching a stale settings page.

**No review appears after opening a pull request.** Gitar automatically processes activity on new pull requests in connected repositories. For an existing pull request, use the **Try Gitar on Open PRs** card in the Gitar dashboard.

**CI doesn't rerun after Gitar pushes a fix.** GitHub Actions triggers on pushes to the PR branch, so it should rerun automatically. If it doesn't, the workflow may need manual enablement on template-created repositories. Go to the **Actions** tab in your repository and click the green button to enable workflows if you see a prompt. Alternatively, push an empty commit to the branch, or edit any file through GitHub's web editor and commit the change.

## Resources

- [Gitar](https://gitar.ai)
- [Gitar documentation](https://docs.gitar.ai)
- [Gitar commands reference](https://docs.gitar.ai/commands)
- [Repository configuration](https://docs.gitar.ai/configuration/repository-config)
- [Repository rules](https://docs.gitar.ai/features/rules)
- [CI failure analysis](https://docs.gitar.ai/features/ci-failure-analysis)
