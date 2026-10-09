import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAoMkleqRTz7_yhq0hv-O2Zmeg4QiWanBg',
    appId: '1:265159237074:web:9fdbb4bf7085a961cebc0b',
    messagingSenderId: '265159237074',
    projectId: 'overload-ai-6b074',
    authDomain: 'overload-ai-6b074.firebaseapp.com',
    storageBucket: 'overload-ai-6b074.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLN35L2p5fNICoNhcpa5tzK_xctf3yU94',
    appId: '1:265159237074:android:5777f032a0e77742cebc0b',
    messagingSenderId: '265159237074',
    projectId: 'overload-ai-6b074',
    storageBucket: 'overload-ai-6b074.firebasestorage.app',
  );
}
