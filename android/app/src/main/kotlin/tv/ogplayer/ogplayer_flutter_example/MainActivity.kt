package tv.ogplayer.ogplayer_flutter_example

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity): the OGPlayer plugin needs an
// androidx lifecycle owner for its Compose chrome, and a ComponentActivity
// for picture-in-picture.
class MainActivity : FlutterFragmentActivity()
