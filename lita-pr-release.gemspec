Gem::Specification.new do |spec|
  spec.name          = "lita-pr-release"
  spec.version       = "0.1.1"
  spec.authors       = ["Sammy Lin"]
  spec.email         = ["sammylintw@gmail.com"]
  spec.description   = "use lita run pr release"
  spec.summary       = "use lita run pr release"
  spec.homepage      = "https://github.com/commandp/lita-pr-release"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "octokit"
  spec.add_development_dependency "asana"
  spec.add_development_dependency "slack-notifier"
  spec.add_development_dependency "aws-sdk", '~> 2'
end
