Pod::Spec.new do |s|
s.name             = 'chat-uikit'
s.version          = '1.3.0'
s.summary = 'agora im UIKit'
s.homepage = 'https://github.com/AgoraIO-Usecase/AgoraChat-UIKit-ios'
s.description = <<-DESC
chat-uikit new version
DESC
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'agora' => 'dev@agora.com' }
s.source = { :git => 'https://github.com/AgoraIO-Usecase/AgoraChat-UIKit-ios.git', :tag => s.version.to_s}
s.ios.deployment_target = '13.0'

s.xcconfig = {'ENABLE_BITCODE' => 'NO'}
s.resources = ['Sources/EaseChatUIKit/Classes/UI/**/*.bundle','Sources/EaseChatUIKit/Classes/UI/**/*.xcprivacy']
s.dependency 'HyphenateChat','>= 4.6.0'
s.static_framework = true

s.swift_version = '5.0'
s.prefix_header_contents = '
# if __has_include (<EaseChatUIKit/EaseChatUIKit-Bridge.h>)
#import <EaseChatUIKit/EaseChatUIKit-Bridge.h>
# else
#import "EaseChatUIKit-Bridge.h"
# endif
'
s.public_header_files = 'Sources/EaseChatUIKit/Classes/UI/Foundation/EaseChatUIKit-Bridge.h'

s.preserve_paths =  ['Sources/EaseChatUIKit/Classes/UI/Core/Foundation/third-party/**/*.a','Sources/EaseChatUIKit/Classes/UI/Core/Foundation/third-party/vo-amrwbenc/lib/*.a']


s.vendored_libraries = ['Sources/EaseChatUIKit/Classes/UI/Core/Foundation/third-party/**/*.a','Sources/EaseChatUIKit/Classes/UI/Core/Foundation/third-party/vo-amrwbenc/lib/*.a']

s.xcconfig = { 'LIBRARY_SEARCH_PATHS' => '$(PODS_ROOT)/Sources/EaseChatUIKit/Classes/UI/Core/Foundation/third-party/**/*' } #


s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
'VALID_ARCHS' => 'arm64 armv7 x86_64'
}
s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

s.frameworks = 'UIKit', 'Foundation', 'Combine', 'AudioToolbox', 'AVFoundation','AVFAudio','Photos'

end
