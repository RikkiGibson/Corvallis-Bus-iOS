project.name = "CorvallisBus"

project.all_configurations.each do |configuration|
    configuration.settings["CODE_SIGN_IDENTITY[sdk=iphoneos*]"] = "iPhone Developer"
    configuration.settings["DEVELOPMENT_TEAM"] = "6M3YNUD5R9"
    configuration.settings["SDKROOT"] = "iphoneos"
    configuration.settings["GCC_DYNAMIC_NO_PIC"] = "NO"
    configuration.settings["OTHER_CFLAGS"] = "$(inherited) -DNS_BLOCK_ASSERTIONS=1"
    configuration.settings["GCC_C_LANGUAGE_STANDARD"] = "gnu99"
    configuration.settings["CLANG_ENABLE_MODULES"] = "YES"
    configuration.settings["CLANG_ENABLE_OBJC_ARC"] = "YES"
    configuration.settings["ENABLE_NS_ASSERTIONS"] = "NO"
    configuration.settings["ENABLE_STRICT_OBJC_MSGSEND"] = "YES"
    configuration.settings["CLANG_WARN_EMPTY_BODY"] = "YES"
    configuration.settings["CLANG_WARN_BOOL_CONVERSION"] = "YES"
    configuration.settings["CLANG_WARN_CONSTANT_CONVERSION"] = "YES"
    configuration.settings["GCC_WARN_64_TO_32_BIT_CONVERSION"] = "YES"
    configuration.settings["CLANG_WARN_INT_CONVERSION"] = "YES"
    configuration.settings["GCC_WARN_ABOUT_RETURN_TYPE"] = "YES_ERROR"
    configuration.settings["GCC_WARN_UNINITIALIZED_AUTOS"] = "YES_AGGRESSIVE"
    configuration.settings["CLANG_WARN_UNREACHABLE_CODE"] = "YES"
    configuration.settings["GCC_WARN_UNUSED_FUNCTION"] = "YES"
    configuration.settings["GCC_WARN_UNUSED_VARIABLE"] = "YES"
    configuration.settings["CLANG_WARN_DIRECT_OBJC_ISA_USAGE"] = "YES_ERROR"
    configuration.settings["CLANG_WARN__DUPLICATE_METHOD_MATCH"] = "YES"
    configuration.settings["GCC_WARN_UNDECLARED_SELECTOR"] = "YES"
    configuration.settings["CLANG_WARN_OBJC_ROOT_CLASS"] = "YES_ERROR"
    configuration.settings["CURRENT_PROJECT_VERSION"] = "1"
    configuration.settings["DEFINES_MODULE"] = "YES" # http://stackoverflow.com/a/27251979
    configuration.settings["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone"
    configuration.settings["CLANG_WARN_INFINITE_RECURSION"] = "YES"
    configuration.settings["CLANG_WARN_SUSPICIOUS_MOVE"] = "YES"
    configuration.settings["ENABLE_STRICT_OBJC_MSGSEND"] = "YES"
    configuration.settings["GCC_NO_COMMON_BLOCKS"] = "YES"
    configuration.settings["ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES"] = "$(inherited)"
    configuration.settings["SWIFT_VERSION"] = "4.0"
    configuration.settings["SWIFT_SWIFT3_OBJC_INFERENCE"] = "On";
end

def add_swiftlint(target)
    target.shell_script_build_phase 'SwiftLint', <<-SCRIPT
if which swiftlint >/dev/null; then
    swiftlint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
SCRIPT
end

application_for :ios, 8.0 do |target|
    target.name = "CorvallisBus"
    add_swiftlint(target)

    target.include_files << "Shared/**/*.*"
    target.all_configurations.each do |configuration|
        configuration.settings["CODE_SIGN_ENTITLEMENTS"] = "CorvallisBus/CorvallisBus.entitlements"
        configuration.settings["INFOPLIST_FILE"] = "CorvallisBus/Info.plist"
        configuration.product_bundle_identifier = "Rikki.CorvallisBus"
        configuration.supported_devices = :universal
        configuration.settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
        configuration.settings["ENABLE_BITCODE"] = "YES"
        configuration.settings["SWIFT_OBJC_BRIDGING_HEADER"] = "CorvallisBus/CorvallisBus-BridgingHeader.h"
        configuration.settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
        configuration.settings["OTHER_LDFLAGS"] = "$(inherited) -ObjC"
        configuration.settings["ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES"] = "YES"
    end

    unit_tests_for target do |test_target|
        test_target.name = "CorvallisBusTests"
        test_target.include_files << "Tests/**/*.*"

        test_target.all_configurations.each do |configuration|
            configuration.settings["INFOPLIST_FILE"] = "Tests/Info.plist"
        end
    end

    extension_for target do |ext_target|
        ext_target.name = "CorvallisBusTodayExtension"
        ext_target.include_files << "TodayExtension/**/*.*"
        ext_target.include_files << "Shared/**/*.*"
        ext_target.include_files << "CorvallisBus/Images.xcassets"
        ext_target.exclude_files << "Shared/CorvallisBusManager.swift"
        ext_target.all_configurations.each do |configuration|
            configuration.product_bundle_identifier = "Rikki.CorvallisBus.CorvallisBusTodayExtension"
            configuration.settings["INFOPLIST_FILE"] = "TodayExtension/Info.plist"
            configuration.settings["CODE_SIGN_ENTITLEMENTS"] = "TodayExtension/CorvallisBusTodayExtension.entitlements"
            configuration.settings["SWIFT_OBJC_BRIDGING_HEADER"] = "TodayExtension/TodayExtension-BridgingHeader.h"
            configuration.settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/Frameworks"
            configuration.settings["ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES"] = "NO"
        end

        ext_target.system_frameworks = ["CoreLocation", "NotificationCenter"]
    end

    target.copy_files_build_phase "Embed App Extensions" do |phase|
        phase.destination = :plug_ins
        phase.files = ["Products/CorvallisBusTodayExtension.appex"]
    end
end

application_for :osx, 10.12 do |target|
    target.name = "CorvallisBusMac"
    target.include_files << "Shared/**/*.*"
    target.include_files << "CorvallisBus/BusStopAnnotation.swift"
    target.include_files << "CorvallisBus/StopDetailViewModel.swift"
    target.include_files << "CorvallisBus/BusMapViewModel.swift"
    target.exclude_files << "Shared/Views/BusRouteLabel.swift"
    target.exclude_files << "Shared/Views/FavoriteStopTableViewCell.swift"
    target.all_configurations.each do |configuration|
        configuration.product_bundle_identifier = "Rikki.CorvallisBusMac"
        configuration.settings["INFOPLIST_FILE"] = "CorvallisBusMac/Info.plist"
        configuration.settings["SWIFT_OBJC_BRIDGING_HEADER"] = "CorvallisBusMac/CorvallisBusMac-BridgingHeader.h"
    end

    extension_for target do |ext_target|
        ext_target.name = "TodayExtensionMac"
        ext_target.include_files << "Shared/**/*.*"
        ext_target.include_files << "CorvallisBus/BusStopAnnotation.swift"
        ext_target.include_files << "CorvallisBus/StopDetailViewModel.swift"
        ext_target.include_files << "CorvallisBus/BusMapViewModel.swift"
        ext_target.exclude_files << "Shared/CorvallisBusManager.swift"
        ext_target.exclude_files << "Shared/Views/BusRouteLabel.swift"
        ext_target.exclude_files << "Shared/Views/FavoriteStopTableViewCell.swift"
        ext_target.all_configurations.each do |configuration|
            configuration.settings["INFOPLIST_FILE"] = "TodayExtensionMac/Info.plist"
            configuration.settings["SWIFT_OBJC_BRIDGING_HEADER"] = "CorvallisBusMac/CorvallisBusMac-BridgingHeader.h"
            configuration.settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/../Frameworks @loader_path/../Frameworks"
            configuration.settings["ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES"] = "YES"
        end
        ext_target.system_frameworks = ["AppKit"]

    end

end

project.after_save do |project|
    system <<-SCRIPT
#cp .xcake/*.xcscheme CorvallisBus.xcodeproj/xcshareddata/xcschemes/
pod install
SCRIPT
end
