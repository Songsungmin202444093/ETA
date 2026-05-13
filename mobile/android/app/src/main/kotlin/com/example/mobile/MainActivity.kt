package com.example.mobile

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"com.example.mobile/auth_config",
		).setMethodCallHandler { call, result ->
			if (call.method == "getSocialAuthConfig") {
				val googleServerClientId = BuildConfig.GOOGLE_SERVER_CLIENT_ID
					.takeIf { it.isNotBlank() }

				result.success(
					mapOf(
						"kakaoConfigured" to true,
						"googleConfigured" to BuildConfig.GOOGLE_AUTH_CONFIGURED,
						"naverConfigured" to BuildConfig.NAVER_AUTH_CONFIGURED,
						"googleServerClientId" to googleServerClientId,
					),
				)
			} else {
				result.notImplemented()
			}
		}
	}
}
