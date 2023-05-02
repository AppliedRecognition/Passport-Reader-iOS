# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Passport Reader' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Passport Reader
  pod 'Ver-ID', '~> 2.11.0'
  
  post_install do |installer|
      installer.pods_project.build_configurations.each do |config|
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings.delete 'BUILD_LIBRARY_FOR_DISTRIBUTION'
              config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
          end
      end
  end
end
