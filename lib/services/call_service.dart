// call_service.dart
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class CallService {
  static const int appID = 346350858;
  static const String appSign =
      "0b5a0cc7b9a48620f474ae57318840047a77acf0ddb6e5e82b144d871447fb07";

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
