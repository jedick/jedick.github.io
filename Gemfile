source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins

gem "tzinfo-data"
gem "wdm", "~> 0.1.0" if Gem.win_platform?

# If you have any plugins, put them here!
group :jekyll_plugins do
  gem "jekyll-paginate"
  gem "jekyll-sitemap"
  gem "jekyll-gist"
  gem "jekyll-feed"
  gem "jemoji"
  gem "jekyll-include-cache"
  gem "jekyll-algolia"
end

# 20250220
# /usr/lib64/ruby/3.4.0/bundled_gems.rb:82:in 'Kernel.require': cannot load such file -- mutex_m (LoadError)
# https://github.com/fastlane/fastlane/issues/29183
gem "mutex_m"

## 20251228 Trying ruby 4.0.0
## warning: csv used to be loaded from the standard library, but is not part of the default gems since Ruby 3.4.0.
#gem "csv"
## warning: bigdecimal used to be loaded from the standard library, but is not part of the default gems since Ruby 3.4.0
#gem "bigdecimal"
## warning: ostruct used to be loaded from the standard library, but is not part of the default gems since Ruby 4.0.0
#gem "ostruct"
