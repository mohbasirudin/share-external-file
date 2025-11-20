package id.bee.sharemanual

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {

    private val CHANNEL = "id.bee.sharemanual/share"
    private var methodChannel: MethodChannel? = null
    private lateinit var shareHandler: ShareHandler
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Setup MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Initialize ShareHandler
        shareHandler = ShareHandler(
            contentResolver = contentResolver,
            cacheDir = cacheDir,
            methodChannel = methodChannel
        )
        
        // Setup method call handler
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialShare" -> {
                    val data = shareHandler.getInitialShareData()
                    result.success(data)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle intent saat app pertama kali dibuka
        shareHandler.handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle intent saat app sudah berjalan
        shareHandler.handleIntent(intent)
    }
}