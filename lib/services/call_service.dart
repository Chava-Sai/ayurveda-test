// call_service.dart
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class CallService {
  static const int appID = 1470441275;
  static const String appSign =
      "ffd8cf5b1af88e5a380bf05bb1c1033eda61a1f40e3a10de2c45df847e4914f8";

  static Future<void> initializeCallService({
    required String userID,
    required String userName,
  }) async {
    await ZegoUIKitPrebuiltCallInvitationService().init(
      
      appID: appID,
      appSign: appSign,
      userID: userID,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  static Future<void> uninitialize() async {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
