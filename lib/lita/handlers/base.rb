module Lita::Handlers::PrRelease
  class Base < Lita::Handler
    route(
      %r{get\s(\w*)\scurrent-version},
      :current_version,
      :command => true,
      :help    => {
        'get (api|web) current-version' => '查詢的 Repository latest release tag'
      }
    )

    route(
      %r{^(今天來 release)\s+(.+)},
      :ready_to_release,
      :command => true,
      :help    => {
        '今天來 release (api|web)' => ''
      }
    )

    route(
      %r{diff-pr\s(\w*)\s(.+)~(.+)},
      :diff_pr,
      :command => true,
      :help    => {
        'diff-pr (api|web) master~develop' => '會 diff 所指定的兩個版本 ，會 output `PR`'
      }
    )

    route(
      %r{^diff\s(\w*)\s(.+)~(.+)},
      :diff,
      :command => true,
      :help    => {
        'diff (api|web) master~develop' => '會 diff 所指定的兩個版本 ，會 output `commit`'
      }
    )

    route(
      %r{repo+\s+config},
      :display_repo_config,
      :command => true,
      :help    => {
         'repo config' => '取得 Github Repository 在 Ninja 上的 Config '
      }
    )

    def display_repo_config(response)
      response.reply("```\n #{JSON.pretty_generate(repo_config)}```" )
    end

    def current_version(response)
      repo = find_by_repo(response.matches.flatten[0])

      if repo
        response.reply(":running_dog: 查詢 *#{repo['repo_name']}* 目前版本中.....")

        github = GithubClient.new(ENV['GITHUB_ACCESS_TOKEN'], repo['repo_name'])
        response.reply(github.latest_release_tag)
      else
        response.reply("可是瑞凡...我找了很久就是找不到 #{response.matches.flatten[0]} 喔~")
      end
    end

    def ready_to_release(response)
      repo = find_by_repo(response.matches.flatten[1])
      if repo
        response.reply('報告是！')

        github = GithubClient.new(ENV['GITHUB_ACCESS_TOKEN'], repo['repo_name'])

        github.create_release_branch

        response.reply("已從 develop 拉出 release/#{github.next_version} ~")

        asana_url_list, next_version, pr_html_url = github.create_pr
        response.reply("已建立 release/#{next_version} PR  ~ #{pr_html_url}")

        response.reply('前進 ASANA 打 Tag ！')
        asana = AsanaClient.new(ENV['ASANA_ACCESS_TOKEN'], ENV['ASANA_WORKSPACE'])

        asana.run_version(pr_html_url, repo['prefix'], next_version, pr_html_url)
        response.reply('打完 Tags 了')
      else
        response.reply("可是瑞凡...我找了很久就是找不到 #{response.matches.flatten[1]} 喔~")
      end
    end

    def diff_pr(response)
      repo = find_by_repo(response.matches.flatten[0])
      if repo
        begin
          response.reply(":running_dog: 比對 #{repo['repo_name']} #{response.matches.flatten[1]}...#{response.matches.flatten[2]} 的 Pull Request 中.....(小聲說...會跑很久喔~)")
          slack = Slack::Notifier.new('https://hooks.slack.com/services/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')

          github = GithubClient.new(ENV['GITHUB_ACCESS_TOKEN'], repo['repo_name'])
          diff = github.diff_pr(response.matches.flatten[1], response.matches.flatten[2])
          diff.empty? ? response.reply('> 比對過後 *無差別* 喔...') : with_link_message(response, "比對 #{repo['repo_name']} #{response.matches.flatten[1]}...#{response.matches.flatten[2]} 的 Pull Request 的結果", render_text(diff))

        rescue Exception => e
          response.reply "> 發生錯誤：#{e.message}"
        end
      else
        response.reply("可是瑞凡...我找了很久就是找不到 #{response.matches.flatten[0]} 喔~")
      end
    end

    def diff(response)
      repo = find_by_repo(response.matches.flatten[0])
      if repo
        begin
          response.reply(":running_dog: 比對 #{repo['repo_name']} #{response.matches.flatten[1]}...#{response.matches.flatten[2]} 的 commit 中....")

          github = GithubClient.new(ENV['GITHUB_ACCESS_TOKEN'], repo['repo_name'])
          diff = github.diff(response.matches.flatten[1], response.matches.flatten[2])
          diff.empty? ? response.reply('> 比對過後 *無差別* 喔...') : with_link_message(response, "比對 #{repo['repo_name']} #{response.matches.flatten[1]}...#{response.matches.flatten[2]} 的 commit 的結果", render_text(diff))
        rescue Exception => e
          response.reply "> 發生錯誤：#{e.message}"
        end
      else
        response.reply "可是瑞凡...我找了很久就是找不到 #{response.matches.flatten[0]} 喔~"
      end
    end

    private

    def with_link_message(response, title, message)
      notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_URL'],
                                     channel: response.room.name
      attachment = {
        fallback: title,
        text: message,
        color: 'good'
      }
      notifier.ping title, attachments: [attachment]
    end

    def render_text(message)
      if message.bytesize > 16000
        "#{message[0..15000]}... \n* 【超過 slack 所限制的 16000 bytes 唷~】*"
      else
        message
      end
    end

    def find_by_repo(short_name)
      repo_config['repo'].select {|key| key['short_name'] == short_name }.first
    end

    def repo_config
      JSON.parse(ENV['REPO_JSON'])
    end
    Lita.register_handler(self)
  end
end
