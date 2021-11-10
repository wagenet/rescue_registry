$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rescue_registry/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rescue_registry"
  spec.version     = RescueRegistry::VERSION
  spec.authors     = ["Peter Wagenet"]
  spec.email       = ["peter.wagenet@gmail.com"]
  spec.homepage    = "https://github.com/wagenet/rescue_registry"
  spec.summary     = "Registry for Rails Exceptions"
  # spec.description = "TODO: Description of RescueRegistry"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 2.3"

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/wagenet/rescue_registry/issues",
    "changelog_uri"     => "https://github.com/wagenet/rescue_registry/CHANGELOG.md",
    "source_code_uri"   => "https://github.com/wagenet/rescue_registry"
    # "documentation_uri" => "https://www.example.info/gems/bestgemever/0.0.1",
    # "mailing_list_uri"  => "https://groups.example.com/bestgemever",
    # "wiki_uri"          => "https://example.com/user/bestgemever/wiki"
  }

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]

  spec.add_dependency "activesupport", ">= 5.0"

  spec.add_development_dependency "appraisal", "~> 2.2"
  spec.add_development_dependency "kramdown-parser-gfm", "~> 1.0"
  spec.add_development_dependency "rouge", "~> 3.3"
  spec.add_development_dependency "yard", "~> 0.9"
end
