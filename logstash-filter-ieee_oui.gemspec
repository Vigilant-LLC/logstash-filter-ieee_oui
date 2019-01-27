Gem::Specification.new do |s|
  s.name          = 'logstash-filter-ieee_oui'
  s.version       = '1.0.3'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Logstash filter to parse OUI data from mac addresses, requires external OUI txt file from ieee.org'
  s.description   = 'This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program'
  s.homepage      = 'https://github.com/Vigilant-LLC/logstash-filter-ieee_oui'
  s.authors       = ['Mike Pananen']
  s.email         = 'panaman@geekempire.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.60", "<= 2.99"
  s.add_development_dependency 'logstash-devutils', '= 1.3.6'
end
