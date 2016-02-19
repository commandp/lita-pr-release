module Lita::Handlers::PrRelease
  class AsanaClient
    include Lita::Handler::Common
    attr_accessor :version
    attr_reader :client

    def initialize(api_token, workspace_name)
      @client = ::Asana::Client.new do |c|
        c.authentication :access_token, api_token
      end
      @workspace = find_workspace(workspace_name)
      @tag = nil
    end

    def tag
      @workspace.typeahead(type: 'tagxxx', query: @version).first || create_tag
    end

    def task(task_id)
      client.tasks.find_by_id(task_id)
    end

    def find_workspace(workspace_name)
      workspace = client.workspaces.find_all.map do |workspaces|
        workspaces if workspaces.name == workspace_name
      end.first

      fail "No Found #{workspace_name} workspace" if workspace.nil?
      workspace
    end

    def run_version(asana_list, prefix, version, pr_url)
      @version = "#{prefix}#{version}"
      @tag = tag
      asana_list.each do |url|
        url.match(%r{https://app.asana.com/(\d?)\/(\d+)\/(\d+)})
        add_version_to_task(task($3), pr_url)
      end
    end

    private

    def create_tag
      @client.tags.create_in_workspace(workspace: @workspace.id, name: @version)
    end

    def add_version_to_task(task, url)
      task.add_tag(tag: @tag.id)
      task.add_comment(text: "HI #{assignees(task)} 您好\n" \
                             "已經啟用 #{@version} branch" \
                             "詳情請參考：#{url} ！")
    end

    def assignees(task)
      projects = [task.projects.map do |project|
        { id: project.id, name: project.name }
      end].flatten!
      projects = projects.each_with_object([]) do |(k, _v), array|
        array << k if k[:name] =~ /#{@workspace.name}/
      end
      projects.map do |project|
        "https://app.asana.com/0/#{project[:id]}/#{project[:id]}"
      end.join(' ')
    end
  end
end
