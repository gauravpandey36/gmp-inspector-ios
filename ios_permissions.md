# iOS Permissions Required

Add these to ios/Runner/Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>GMP Inspector needs camera access to capture facility photos for compliance analysis</string>
<key>NSMicrophoneUsageDescription</key>
<string>GMP Inspector needs microphone access for video recording during facility walkthroughs</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>GMP Inspector needs photo library access to analyze images from Meta Ray-Ban glasses</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>GMP Inspector uses speech for reading compliance findings aloud</string>
```
