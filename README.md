# lita-pr-release

可以直接用 lita 開 pr release brunch ，也可以執行 `diff` or `diff-pr`

## Installation

Add lita-pr-release to your Lita instance's Gemfile:

``` ruby
gem "lita-pr-release", git: 'https://github.com/commandp/lita-pr-release.git'
```

## Usage

```sh
SLACK_WEBHOOK_URL='https://hooks.slack.com/services/xxx/ooo/xxx' \
GITHUB_ACCESS_TOKEN='<github_access_token' \
ASANA_ACCESS_TOKEN='<asana_access_token>' \
ASANA_WORKSPACE='<asana_workspace>' \
REPO_JSON='{"repo": [{ "short_name": "api", "repo_name": "ooo/xxx-api", "prefix": "B-" }, { "short_name": "web", "repo_name": "ooo/xxx-web", "prefix": "F-" }] }' \
lita
```
