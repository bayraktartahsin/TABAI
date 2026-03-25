package com.taba.tabai.data.remote.sse

import com.taba.tabai.core.config.AppConfig
import com.taba.tabai.data.dto.StreamRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.BufferedReader
import java.io.InputStreamReader

data class SSEEvent(val event: String, val data: String)

class SSEClient(private val client: OkHttpClient, private val json: Json) {

    fun stream(request: StreamRequest): Flow<SSEEvent> = callbackFlow {
        val body = json.encodeToString(request)
            .toRequestBody("application/json".toMediaType())

        val httpRequest = Request.Builder()
            .url("${AppConfig.BASE_URL}/api/chat/stream")
            .post(body)
            .header("Accept", "text/event-stream")
            .build()

        val response = withContext(Dispatchers.IO) {
            client.newCall(httpRequest).execute()
        }

        if (!response.isSuccessful || response.body == null) {
            val errorText = response.body?.string() ?: "Stream failed (${response.code})"
            trySend(SSEEvent("error", errorText))
            close()
            return@callbackFlow
        }

        val reader = BufferedReader(InputStreamReader(response.body!!.byteStream()))
        var currentEvent = ""
        var currentData = StringBuilder()

        try {
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                val l = line!!
                when {
                    l.startsWith("event:") -> currentEvent = l.removePrefix("event:").trim()
                    l.startsWith("data:") -> currentData.append(l.removePrefix("data:").trim())
                    l.isBlank() -> {
                        if (currentEvent.isNotEmpty() || currentData.isNotEmpty()) {
                            trySend(SSEEvent(currentEvent.ifEmpty { "message" }, currentData.toString()))
                            currentEvent = ""
                            currentData = StringBuilder()
                        }
                    }
                }
            }
            // Flush remaining
            if (currentEvent.isNotEmpty() || currentData.isNotEmpty()) {
                trySend(SSEEvent(currentEvent.ifEmpty { "message" }, currentData.toString()))
            }
        } catch (e: Exception) {
            trySend(SSEEvent("error", e.message ?: "Stream interrupted"))
        } finally {
            reader.close()
            response.close()
        }

        awaitClose { response.close() }
    }
}
