#
# Be sure to run `pod lib lint CalendarSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CalendarSwift'
  s.version          = `git describe --abbrev=0 --tags`
  s.summary          = 'Custom calendar'
  s.description      = <<-DESC
  'Custom calendar for iOS.'
  DESC
  s.homepage         = 'https://github.com/raketenok/CalendarSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ievgen Iefimenko' => 'raketenok@gmail.com' }
  s.source           = { :git => 'https://github.com/raketenok/CalendarSwift.git', :tag => s.version }
  s.ios.deployment_target = '10.0'
  s.swift_version = '4.0'

  s.resource_bundles = {
    'CalendarSwift.resources' => [
      'Sources/*.xcassets'
    ]
  }
  s.resources = [
    'Sources/*.xcassets'
  ]
  s.source_files = 'Sources/**/*.swift'
end
