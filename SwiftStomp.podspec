#
# Be sure to run `pod lib lint SwiftStomp.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftStomp'
  s.version          = '0.1.1'
  s.summary          = 'An elegant Stomp client for iOS.'
  s.description      = <<-DESC
  SwiftStomp is and elegant, light-weight and easy-to-use STOMP (Simple Text Oriented Messaging Protocol) client for iOS.
  It's based on Starscream, an amazing Websocket library for swift.
                         DESC
 
  s.homepage         = 'https://github.com/Romixery/SwiftStomp'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Romixery' => 'topcoder.romixery@gmail.com' }
  s.source           = { :git => 'https://github.com/Romixery/SwiftStomp.git', :tag => s.version.to_s }
  s.author       = {'Ahmad Daneshvar' => 'http://iamdaneshvar.com'}
  s.source       = { :git => 'https://github.com/Romixery/SwiftStomp.git',  :tag => "#{s.version}"}

  s.ios.deployment_target = '8.0'
  s.swift_version    = '5.0'
  s.source_files = 'SwiftStomp/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SwiftStomp' => ['SwiftStomp/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Starscream', '~> 4.0.0'
end
