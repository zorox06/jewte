package app.jewte.jewte

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/** Widgets display a compact mirror; the checklist has only one writer in Flutter. */
object JewteWidgets {
    val worker = Executors.newSingleThreadExecutor()
    private const val PREFS = "jewte_home_widgets"
    private const val SNAPSHOT = "snapshot_v1"

    fun snapshot(context: Context): JSONObject {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(SNAPSHOT, null)
        if (raw != null) {
            try { return JSONObject(raw) } catch (_: Exception) { /* Recreate a display-only default. */ }
        }
        val catalog = context.assets.open("flutter_assets/assets/data/catalog.json").bufferedReader().use { JSONObject(it.readText()) }
        val topics = catalog.getJSONArray("topics")
        val first = topics.getJSONObject(0)
        return JSONObject().put("total", topics.length()).put("completed", 0).put("saved", 0)
            .put("nextId", first.getString("id")).put("nextTitle", first.getString("title"))
            .put("nextSubject", "C Programming").put("nextQuery", first.getString("title"))
    }

    fun sync(context: Context, raw: String) {
        val state = JSONObject(raw)
        val total = state.getInt("total")
        require(total > 0 && state.getInt("completed") in 0..total)
        require(state.getInt("saved") >= 0)
        require(state.getString("nextId").length in 1..100)
        require(state.getString("nextTitle").length in 1..1000)
        // The native shortcut follows the exact same topic-only search policy.
        state.put("nextQuery", state.getString("nextTitle"))
        check(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(SNAPSHOT, state.toString()).commit())
        updateAll(context)
    }

    private fun openApp(context: Context, destination: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse("jewte://$destination")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(context, destination.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    fun views(context: Context, kind: String, data: JSONObject = snapshot(context)): RemoteViews {
        val progress = kind == "progress"
        val result = RemoteViews(context.packageName, if (progress) R.layout.widget_progress else R.layout.widget_topic)
        val total = data.optInt("total", 1).coerceAtLeast(1)
        val done = data.optInt("completed", 0).coerceIn(0, total)
        if (progress) {
            result.setTextViewText(R.id.widget_percent, "${done * 100 / total}%")
            result.setTextViewText(R.id.widget_completed, "$done of $total concepts")
            result.setTextViewText(R.id.widget_remaining, "${total - done} remaining  ·  ${data.optInt("saved", 0)} saved")
            result.setProgressBar(R.id.widget_progress_bar, total, done, false)
            result.setOnClickPendingIntent(R.id.widget_root, openApp(context, "library"))
        } else {
            val title = data.optString("nextTitle", "Explore a concept")
            result.setTextViewText(R.id.widget_topic_title, title)
            result.setTextViewText(R.id.widget_topic_subject, data.optString("nextSubject", "Your study space"))
            val open = openApp(context, "topic/${data.optString("nextId")}")
            result.setOnClickPendingIntent(R.id.widget_root, open)
            result.setOnClickPendingIntent(R.id.widget_continue, open)
            val youtube = Intent(Intent.ACTION_VIEW, Uri.Builder().scheme("https").authority("www.youtube.com")
                .path("/results").appendQueryParameter("search_query", title).build()).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
            result.setOnClickPendingIntent(R.id.widget_youtube, PendingIntent.getActivity(context, ("youtube:$title").hashCode(), youtube,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        }
        return result
    }

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for ((kind, provider) in listOf("progress" to ProgressWidgetProvider::class.java, "topic" to TopicWidgetProvider::class.java)) {
            val ids = manager.getAppWidgetIds(ComponentName(context, provider))
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, views(context, kind))
        }
    }

    fun info(context: Context): Map<String, Any> {
        val manager = AppWidgetManager.getInstance(context)
        return mapOf("supported" to true,
            "pinSupported" to (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported),
            "progressCount" to manager.getAppWidgetIds(ComponentName(context, ProgressWidgetProvider::class.java)).size,
            "topicCount" to manager.getAppWidgetIds(ComponentName(context, TopicWidgetProvider::class.java)).size,
            "snapshot" to snapshot(context).toString())
    }

    /** Render the actual RemoteViews used by the launcher, not a second mockup. */
    fun preview(context: Context, kind: String, width: Int, height: Int): ByteArray {
        require(width in 240..1600 && height in 120..1000)
        val configuration = Configuration(context.resources.configuration).apply { densityDpi = 320; fontScale = 1f }
        val previewContext = context.createConfigurationContext(configuration)
        val view = views(previewContext, kind).apply(previewContext, null)
        view.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
        view.layout(0, 0, width, height)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        view.draw(Canvas(bitmap))
        return ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
            bitmap.recycle()
            output.toByteArray()
        }
    }
}

class ProgressWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val pending = goAsync()
        JewteWidgets.worker.execute {
            try { manager.updateAppWidget(ids, JewteWidgets.views(context, "progress")) } finally { pending.finish() }
        }
    }
}

class TopicWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val pending = goAsync()
        JewteWidgets.worker.execute {
            try { manager.updateAppWidget(ids, JewteWidgets.views(context, "topic")) } finally { pending.finish() }
        }
    }
}
