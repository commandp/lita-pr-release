require 'lita'
require 'octokit'
require 'slack-notifier'
require 'erb'
require 'aws-sdk'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'lita/handlers/base'
require 'lita/handlers/github_client'
require 'lita/handlers/asana_client'

# Lita::Handlers::PrRelease.template_root File.expand_path(
#   File.join('..', '..', 'templates'),
#  __FILE__
# )
