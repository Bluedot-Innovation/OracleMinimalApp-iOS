# OracleMinimalApp-iOS
Oracle Minimal App integration for iOS
The Bluedot SDK integration with Oracle Responsys Mobile App Platform Cloud Service enables mobile apps to take advantage of the power of  Cloud services and the superior accuracy, Geofence, Geolines™ and BLE Beacon triggering capabilities of the Bluedot SDKs.
To take the full advantage of the Oracle Cloud services, it is mandatory to integrate needed libraries/frameworks generally called as SDKs to your mobile app.
At this moment, only iOS and Android mobile applications are supported by the SDK.
This page contains steps on how to update your mobile app’s source and integrate the app with Bluedot Point SDK.

Please refer integration steps mentioned at : https://docs.bluedot.io/integrations/oracle-integration/

For latest Bluedot Point SDK 15.6.1, New xcframework needs to be created as the PointSDK is built for iOS device and Simulators and it will report error as the OracleMinimalApp project only builds for iOS device.
Follow below steps to fix the error by create a new xcframework:
1. Run carthage bootstrap --use-xcframeworks
2. Now BDPointSDK.xcframework must be downloaded in the Carthage folder.
3. Locate both variants of BDpoint.xcframework for ios-arm64_armv7 and ios-arm64_i386_x86_64-simulator
4. Run below command to create a new xcframework using both the variants
xcodebuild -create-xcframework -framework Carthage/Checkouts/PointSDK-iOS/PointSDK/BDPointSDK.xcframework/ios-arm64_armv7/BDPointSDK.framework/ -framework Carthage/Checkouts/PointSDK-iOS/PointSDK/BDPointSDK.xcframework/ios-arm64_i386_x86_64-simulator/BDPointSDK.framework/ -output BDPoint.xcframework
5. Now add new created BDPoint.xcframework in Frameworks,Libraries and Embedded Content section and select Embed & Sign option
6. Now App can be build successfully with xcframework
