Gem::Specification.new do |spec|
  spec.name = %q{rfgw}
  spec.version = "1.0.0"
  spec.date = %q{2019-04-22}
  spec.summary = %q{Gem to interact with Cisco RFGW-1}
  spec.authors = ['Shaun Garwood']
  spec.license = 'Nonstandard'
  spec.files = [
    "lib/rfgw.rb",
    "lib/rfgw/maps.rb",
    "lib/rfgw/maps/maps-get.rb",
    "lib/rfgw/maps/maps-post.rb",
    "lib/rfgw/qams.rb",
    "lib/rfgw/system.rb",
    "bin/test.rb"
  ]
  spec.require_paths = ["lib"]
end
