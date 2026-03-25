package com.taba.tabai.di

import android.content.Context
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.taba.tabai.core.config.AppConfig
import com.taba.tabai.data.local.DataStoreManager
import com.taba.tabai.data.remote.api.TABAIApi
import com.taba.tabai.data.remote.interceptor.PersistentCookieJarImpl
import com.taba.tabai.data.remote.sse.SSEClient
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideJson(): Json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }

    @Provides
    @Singleton
    fun provideCookieJar(@ApplicationContext context: Context): PersistentCookieJarImpl =
        PersistentCookieJarImpl(context)

    @Provides
    @Singleton
    fun provideOkHttpClient(cookieJar: PersistentCookieJarImpl): OkHttpClient =
        OkHttpClient.Builder()
            .cookieJar(cookieJar)
            .connectTimeout(AppConfig.CONNECT_TIMEOUT_SEC, TimeUnit.SECONDS)
            .readTimeout(AppConfig.READ_TIMEOUT_SEC, TimeUnit.SECONDS)
            .writeTimeout(AppConfig.WRITE_TIMEOUT_SEC, TimeUnit.SECONDS)
            .build()

    @Provides
    @Singleton
    fun provideRetrofit(client: OkHttpClient, json: Json): Retrofit =
        Retrofit.Builder()
            .baseUrl(AppConfig.BASE_URL)
            .client(client)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()

    @Provides
    @Singleton
    fun provideApi(retrofit: Retrofit): TABAIApi = retrofit.create(TABAIApi::class.java)

    @Provides
    @Singleton
    fun provideSSEClient(client: OkHttpClient, json: Json): SSEClient = SSEClient(client, json)

    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStoreManager = DataStoreManager(context)
}
