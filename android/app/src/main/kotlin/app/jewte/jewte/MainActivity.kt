package app.jewte.jewte

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var pendingDestination: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingDestination = destination(intent)
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.jewte/widgets").also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeLaunchAction" -> { val action = pendingDestination; pendingDestination = null; result.success(action) }
                    "syncProgress" -> JewteWidgets.worker.execute {
                        try { JewteWidgets.sync(applicationContext, call.arguments as String); runOnUiThread { result.success(null) } }
                        catch (error: Exception) { runOnUiThread { result.error("WIDGET_SYNC", error.message, null) } }
                    }
                    "widgetInfo" -> JewteWidgets.worker.execute {
                        try { val info = JewteWidgets.info(applicationContext); runOnUiThread { result.success(info) } }
                        catch (error: Exception) { runOnUiThread { result.error("WIDGET_INFO", error.message, null) } }
                    }
                    "requestPin" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        if (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported) {
                            val provider = if (call.argument<String>("kind") == "topic") TopicWidgetProvider::class.java else ProgressWidgetProvider::class.java
                            result.success(manager.requestPinAppWidget(ComponentName(this, provider), null, null))
                        } else result.success(false)
                    }
                    "renderPreview" -> {
                        try { result.success(JewteWidgets.preview(this, call.argument<String>("kind") ?: "progress", call.argument<Int>("width") ?: 720, call.argument<Int>("height") ?: 360)) }
                        catch (error: Exception) { result.error("WIDGET_PREVIEW", error.message, null) }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingDestination = destination(intent)
        if (pendingDestination != null) widgetChannel?.invokeMethod("launchAction", null)
    }
    private fun destination(intent: Intent?): Map<String, String>? {
        val uri = intent?.data ?: return null
        if (uri.scheme != "jewte") return null
        return when (uri.host) {
            "library" -> mapOf("kind" to "library")
            "topic" -> uri.lastPathSegment?.let { mapOf("kind" to "topic", "topicId" to it) }
            else -> null
        }
    }
}
