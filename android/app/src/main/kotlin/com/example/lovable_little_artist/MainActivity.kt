package com.example.lovable_little_artist

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val preferences = getSharedPreferences("little_artist_storage", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "little_artist/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readSavedArtworks" -> result.success(preferences.getString("saved_artworks_v1", null))
                    "writeSavedArtworks" -> {
                        preferences.edit()
                            .putString("saved_artworks_v1", call.arguments as? String ?: "[]")
                            .apply()
                        result.success(null)
                    }
                    "clearSavedArtworks" -> {
                        preferences.edit().remove("saved_artworks_v1").apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
