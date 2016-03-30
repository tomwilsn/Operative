    #
# Be sure to run `pod lib lint Operative.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Operative"
  s.version          = "0.1.0"
  s.summary          = "Advanced NSOperations. Objective-C Port of the sample code in the Apple WWDC 2015 presentation \"Advanced NSOperations\""
  s.description      = <<-DESC

                        Provides a NSOperation sublass with a more advanced state machine.

                        Some features provided:
                          - Easily perform asynchronous 'work' in an operation - even displaying UI such as UIAlertController's
                          - Optionally support 'exclusiviity' guarantees across mulitple instances of the same operation class, even across multiple queues!
                          - Operation delegate - be informed when an operation starts, finishes, or produces sub-operations

                       DESC
  s.homepage         = "https://github.com/Kabal/Operative"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Tom Wilson" => "tom@toms-stuff.net" }
  s.source           = { :git => "https://github.com/Kabal/Operative.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tomwilson'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.requires_arc = true

  s.source_files     = 'Pod/Classes/Operative.h'
  s.ios.source_files = 'Pod/Classes/{Core,iOS}/**/*'
  s.osx.source_files = 'Pod/Classes/{Core,OSX}/**/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'

  s.ios.frameworks = 'UIKit', 'AVFoundation'
  
  # s.dependency 'AFNetworking', '~> 2.3'
end
