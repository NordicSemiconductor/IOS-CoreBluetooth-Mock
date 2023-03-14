Pod::Spec.new do |s|
  s.name             = 'CoreBluetoothMock'
  s.version          = '0.16.1'
  s.summary          = 'Mocking library for CoreBluetooth.'

  s.description      = <<-DESC
This is a mocking library for CoreBluetooth framework. Allows to mock a Bluetooth Low Energy
device and test the app on simulator.
                       DESC

  s.homepage         = 'https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock'
  s.license          = { :type => 'BSD 3-Clause', :file => 'LICENSE' }
  s.author           = { 'Aleksander Nowakowski' => 'aleksander.nowakowski@nordicsemi.no' }
  s.source           = { :git => 'https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nordictweets'

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '11.0'
  s.watchos.deployment_target = '4.0'
  s.swift_versions = ['4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6']

  s.source_files = 'CoreBluetoothMock/**/*'
end
