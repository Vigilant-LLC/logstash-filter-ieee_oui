# logstash-filter-ieee_oui

## Documentation

This Logstash filter plugin is used to match mac addresses to vendor names.

This is a plugin for [Logstash](https://github.com/elastic/logstash).

The filter requires a specially formatted oui-logstash.txt file for the ouifile.
See [logstash-oui-scraper](https://github.com/figure-of-late/logstash-oui-scraper)

See [CHANGELOG](https://github.com/figure-of-late/logstash-filter-ieee_oui/blob/master/CHANGELOG.md) for development notes.

#### USAGE
```
filter {
  ieee_oui {
    source => 'macaddress'
    target => 'oui_vendor'
    ouifile => '/path_to/oui-logstash.txt'
  }
}
```

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Clone this repository

- Update your dependencies

```sh
bundle install
```

#### Run in an installed Logstash

- Build your plugin gem
```sh
gem build logstash-filter-ieee_oui.gemspec
```
- Install the plugin from the Logstash home
```sh
bin/logstash-plugin install /your/local/plugin/logstash-filter-ieee_oui.gem
```
- Start Logstash and proceed to test the plugin

# License
It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way. [LICENSE](https://github.com/figure-of-late/logstash-filter-ieee_oui/blob/master/LICENSE)

