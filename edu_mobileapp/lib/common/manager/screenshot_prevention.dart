import 'package:flutter/services.dart';
import 'package:geoedu/common/manager/logger.dart';

class ScreenshotPrevention {
  ScreenshotPrevention._();
  static final instance = ScreenshotPrevention._();

  static const _channel = MethodChannel('com.geoedu.app/screenshot');

  Future<void> enable() async {
    try {
      Loggers.info('ScreenshotPrevention: calling enableSecure...');
      final result = await _channel.invokeMethod('enableSecure');
      Loggers.info('ScreenshotPrevention: enableSecure result=$result');
    } catch (e) {
      Loggers.error('ScreenshotPrevention: enableSecure FAILED: $e');
    }
  }

  Future<void> disable() async {
    try {
      Loggers.info('ScreenshotPrevention: calling disableSecure...');
      await _channel.invokeMethod('disableSecure');
    } catch (e) {
      Loggers.error('ScreenshotPrevention: disableSecure FAILED: $e');
    }
  }
}
