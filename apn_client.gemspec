# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "apn_client/version"

Gem::Specification.new do |s|
  s.name        = "apn_client"
  s.version     = ApnClient::VERSION
  s.authors     = ["Peter Marklund"]
  s.email       = ["peter@marklunds.com"]
  s.homepage    = ""
  s.summary     = %q{Library for sending Apple Push Notifications to iOS devices from Ruby}
  s.description = %q{Uses the "enhanced format" Apple protocol and deals with errors and failures when broadcasting to many devices. Includes support for talking to the Apple Push Notification Feedback service for dealing with uninstalled apps.}

  s.rubyforge_project = "apn_client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "json"
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "yard"
end
