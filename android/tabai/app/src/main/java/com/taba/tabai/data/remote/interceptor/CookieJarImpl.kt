package com.taba.tabai.data.remote.interceptor

import android.content.Context
import android.content.SharedPreferences
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl

/**
 * Persistent cookie jar that survives app restarts.
 * Cookies are stored in SharedPreferences as OkHttp toString() format.
 */
class PersistentCookieJarImpl(context: Context) : CookieJar {
    private val prefs: SharedPreferences = context.getSharedPreferences("tai_cookies_v2", Context.MODE_PRIVATE)
    private val memoryStore = mutableMapOf<String, MutableList<Cookie>>()

    init { loadAll() }

    override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
        val host = url.host
        val existing = memoryStore.getOrPut(host) { mutableListOf() }
        for (cookie in cookies) {
            existing.removeAll { it.name == cookie.name && it.domain == cookie.domain && it.path == cookie.path }
            existing.add(cookie)
        }
        persist(host, existing)
    }

    override fun loadForRequest(url: HttpUrl): List<Cookie> {
        val now = System.currentTimeMillis()
        return memoryStore[url.host]?.filter { it.expiresAt > now }?.filter { it.matches(url) } ?: emptyList()
    }

    fun clear() {
        memoryStore.clear()
        prefs.edit().clear().apply()
    }

    private fun persist(host: String, cookies: List<Cookie>) {
        // Store each cookie as "name|value|domain|path|expiresAt|secure|httpOnly"
        val lines = cookies.map { c ->
            "${c.name}\t${c.value}\t${c.domain}\t${c.path}\t${c.expiresAt}\t${c.secure}\t${c.httpOnly}"
        }
        prefs.edit().putString(host, lines.joinToString("\n")).apply()
    }

    private fun loadAll() {
        for ((host, raw) in prefs.all) {
            if (raw !is String || raw.isEmpty()) continue
            val cookies = raw.split("\n").mapNotNull { line ->
                try {
                    val parts = line.split("\t")
                    if (parts.size < 7) return@mapNotNull null
                    val builder = Cookie.Builder()
                        .name(parts[0])
                        .value(parts[1])
                        .domain(parts[2])
                        .path(parts[3])
                        .expiresAt(parts[4].toLong())
                    if (parts[5] == "true") builder.secure()
                    if (parts[6] == "true") builder.httpOnly()
                    builder.build()
                } catch (e: Exception) { null }
            }.filter { it.expiresAt > System.currentTimeMillis() }
            if (cookies.isNotEmpty()) {
                memoryStore[host] = cookies.toMutableList()
            }
        }
    }
}
