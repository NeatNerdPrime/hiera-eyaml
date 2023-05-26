source 'https://rubygems.org/'

# Find a location or specific version for a gem. place_or_version can be a
# version, which is most often used. It can also be git, which is specified as
# `git://somewhere.git#branch`. You can also use a file source location, which
# is specified as `file://some/location/on/disk`.
def location_for(place_or_version, fake_version = nil)
  if place_or_version =~ /^(https[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place_or_version =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place_or_version, { :require => false }]
  end
end

gemspec

group :development do
  gem "aruba", '~> 0.6.2'
  gem "cucumber", '~> 1.1'
  gem "hiera-eyaml-plaintext"
  gem 'puppet', *location_for(ENV['PUPPET_VERSION']) if ENV['PUPPET_VERSION']
  gem "activesupport"
end

group :release do
  gem 'faraday-retry', require: false
  gem 'github_changelog_generator', require: false
end

group :coverage, optional: ENV['COVERAGE'] != 'yes' do
  gem 'simplecov-console', :require => false
  gem 'codecov', :require => false
end
