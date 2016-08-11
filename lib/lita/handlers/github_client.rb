module Lita::Handlers::PrRelease
  class GithubClient
    include Lita::Handler::Common
    DEFAULT_PR_TEMPLATE = <<ERB
Release <%= Time.now %>
<% pull_requests.each do |pr| -%>
<%=  pr %>
<% end -%>
ERB
    attr_accessor :clinet
    attr_accessor :asana_url_list
    attr_accessor :next_version
    attr_accessor :merged_feature_head_sha1s

    def initialize(access_token, repository)
      @client = Octokit::Client.new(access_token: access_token)
      @repository = repository
      @latest_release_tag = latest_release_tag
      @next_version = new_version(@latest_release_tag)
      @asana_url_list = []
      @pr_html_url = ''
    end

    def new_version(lastest_version)
      if %r{^(\d{1,2})\.(\d{1,2})\.(\d{1,2})$}.match lastest_version
        "#{$1}.#{$2.to_i + 1}.0"
      end
    end

    def latest_release_tag
      @client.latest_release(@repository).tag_name
    end

    def create_pr
      @merged_feature_head_sha1s = merged_feature_head_sha1s
      @pull_refs = pull_refs
      @merged_prs = merged_prs
      release_pr

      return @asana_url_list, @next_version, @pr_html_url
    end

    def diff(base_branch, compare_branch)
      compare = @client.compare(@repository, base_branch, compare_branch)

      compare[:commits].map.with_index do |commit, index|
        "#{index + 1}." \
        " <#{commit[:html_url]}|#{commit[:sha][0..6]}>" \
        " #{commit[:commit][:message].split(/\n/)[0]}" \
        " @#{commit[:commit][:committer][:name]}\n"
      end.join('')
    end

    def diff_pr(base_branch, compare_branch)
      compare = @client.compare(@repository, base_branch, compare_branch)
      compare_sha = compare.commits.map(&:sha)

      # response.reply(pull_refs.map(&:ref))
      pr_ids = pull_refs.map do |ref|
        if compare_sha.include? ref[:object][:sha]
          if %r{^refs/pull/(\d+)/head$}.match ref[:ref]
            $1.to_i
          else
            nil
          end
        end
      end.compact

      pr_ids.map.with_index do |nr, index|
        pr = @client.pull_request(@repository, nr)
        "#{index + 1}." \
        " <#{pr.html_url}|##{pr.number}>" \
        " #{pr.title}" \
        " #{(pr.assignee ? " @#{pr.assignee.login}" : pr.user ? " @#{pr.user.login}" : '')}" \
        "\n"
      end.join('')
    end

    def create_release_branch
      refs = @client.refs(@repository, 'heads')
      found_branch = refs.map { |ref| ref if ref[:ref] =~ %r{release/#{@next_version}} }.compact.first
      if found_branch
        found_branch
      else
        develop_branch = refs.map { |ref| ref if ref[:ref] =~ %r{heads/develop} }.compact.first
        develop_sha1 = develop_branch[:object][:sha]
        @client.create_ref(@repository,
                           "heads/release/#{@next_version}",
                           develop_sha1)
      end
    end

    private

    def merged_feature_head_sha1s
      compare = @client.compare(@repository, 'master', "release/#{@next_version}")
      compare.commits.map(&:sha)
    end

    def pull_refs
      @client.refs(@repository, 'pull')
    end

    def merged_pull_request_numbers
      @pull_refs.map do |ref|
        if @merged_feature_head_sha1s.include? ref[:object][:sha]
          if %r{^refs/pull/(\d+)/head$}.match ref[:ref]
            $1.to_i
          else
            nil
          end
        end
      end.compact
    end

    def merged_prs
      pr_ids = merged_pull_request_numbers
      pr_ids.map do |nr|
        @client.pull_request @repository, nr if @client.pull_request(@repository, nr).merged
      end.compact
    end

    def pull_request(id)
      @client.pull_request(@repository, id)
    end

    def related_url(pr)
      urls = URI.extract(pr.body)

      urls.map do |url|
        if url =~ %r{https://(app.asana.com)(.*)}
          @asana_url_list << url
          "\n    - [asana](#{url})"
        elsif url =~ %r{https://(ticket.commandp.com)(.*)}
          "\n    - [Redmine](#{url})"
        elsif url =~ %r{https://(rollbar.com)(.*)}
          "\n    - [rollbar](#{url})"
        end
      end.join('')
    end

    def build_pr_title_and_body
      pull_requests = @merged_prs.map { |pr| "- [ ] ##{pr.number} #{pr.title}" +
                                        (pr.assignee ? " @#{pr.assignee.login}" : pr.user ? " @#{pr.user.login}" : "") +
                                        related_url(pr) }
      template = DEFAULT_PR_TEMPLATE

      template_path = File.join(Dir.pwd, 'pr-release-template.html.erb')
      if File.exist?(template_path)
        template = File.read(template_path)
      end

      erb = ERB.new template, nil, '-'
      content = erb.result binding
      content.split(/\n/, 2)
    end

    def release_pr
      production_branch = 'master'
      staging_branch = "release/#{@next_version}"

      find_pr = @client.pull_requests(@repository).find do |pr|
        pr.head.ref == staging_branch && pr.base.ref == production_branch
      end
      create_mode = find_pr.nil?
      if create_mode
        pr = @client.create_pull_request(
          @repository, production_branch, staging_branch, "#{@next_version} Released at #{DateTime.now.strftime("%Y年%m月%d日")}", ''
        )

      else
        pr = find_pr
      end
      pr_title, pr_body = build_pr_title_and_body

      @client.update_pull_request(@repository, pr.number, title: pr_title,
                                  body: pr_body)
      @client.add_labels_to_an_issue(@repository, pr.number, ['release'])
      @pr_html_url = pr.html_url
    end
  end
end
