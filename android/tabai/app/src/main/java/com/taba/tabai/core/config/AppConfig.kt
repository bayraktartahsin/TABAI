package com.taba.tabai.core.config

object AppConfig {
    const val BASE_URL = "https://ai.gravitilabs.com"
    const val CONNECT_TIMEOUT_SEC = 15L
    const val READ_TIMEOUT_SEC = 90L
    const val WRITE_TIMEOUT_SEC = 30L
    const val DEBUG_NETWORK = false
}

object LegalLinks {
    const val PRIVACY = "${AppConfig.BASE_URL}/tabai/privacy"
    const val TERMS = "${AppConfig.BASE_URL}/tabai/terms"
    const val ACCEPTABLE_USE = "${AppConfig.BASE_URL}/tabai/acceptable-use"
    const val SUBSCRIPTION = "${AppConfig.BASE_URL}/tabai/subscription"
    const val SUPPORT = "${AppConfig.BASE_URL}/tabai/support"
    const val SUPPORT_EMAIL = "tabai@gravitilabs.com"
}
