# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'apphost_frontend/version.rb'

Gem::Specification.new do |s|
  s.name        = "apphost-frontend"
  s.version     = AppHost::Frontend::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["David Kamphausen"]
  s.email       = ["david.kamphausen76@googlemail.com"]
  s.homepage    = "http://github.com/godrin/apphost-frontend"
  s.summary     = %q{Manage your repositories on an apphost server}
  s.description = %q{My description}
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "bundler"

  #                         s.add_development_dependency "rspec"
  #                           # Man files are required because they are ignored by git
  man_files            = Dir.glob("lib/bundler/man/**/*")
  git_files            = `git ls-files`.split("\n") rescue ''
  s.files              = git_files + man_files
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables        = %w(apphost-frontend)
  s.require_paths      = ["lib"]
end
#
