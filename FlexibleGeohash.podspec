Pod::Spec.new do |s|
  s.name             = 'FlexibleGeohash'
  s.version          = '0.0.2'
  s.summary          = 'Very fast library for handling Geohash. Encodable in other than base32.'

  s.description      = <<-DESC
  FlexibleGeohash is a very fast library for handling Geohash.
  Geohash is usually encoded in base32, but it can be encoded in base2/4/8/16/32.
                       DESC

  s.homepage         = 'https://github.com/malt03/FlexibleGeohash'
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = { 'Koji Murata' => 'malt.koji@gmail.com' }
  s.source           = { git: 'https://github.com/malt03/FlexibleGeohash.git', tag: "v#{s.version.to_s}" }

  s.source_files = 'Sources/**/*.swift'
  s.swift_version = '5.2'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '10.0'
  s.watchos.deployment_target = '2.0'
end
