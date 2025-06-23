import 'package:flutter/material.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Error')),
        body: const Center(
          child: Text(
              'There was an error loading the chat. Please try again later.'),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conversations'),
          // actions: const [HomePagePopupMenuButton()],
        ),
        body: ZIMKitConversationListView(
          onPressed: (context, conversation, defaultAction) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ZIMKitMessageListPage(
                    conversationID: conversation.id,
                    conversationType: conversation.type,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
