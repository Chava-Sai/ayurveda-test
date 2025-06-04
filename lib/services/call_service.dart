// call_service.dart
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class CallService {
  static const int appID = 1230004016;
  static const String appSign =
      "df3fb8ed30cd58c313e910e7b2ee763a283d9f62257e992b79266577564744c4";

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
