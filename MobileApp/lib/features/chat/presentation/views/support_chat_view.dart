import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_message_type.dart';
import 'package:alrasmarket/features/chat/data/models/chat_support_session_model.dart';
import 'package:alrasmarket/features/chat/presentation/controller/chat_cubit.dart';
import 'package:alrasmarket/features/chat/presentation/controller/chat_states.dart';
import 'package:alrasmarket/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:alrasmarket/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:alrasmarket/features/chat/presentation/widgets/chat_session_divider.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

sealed class _ThreadItem {}

class _MessageItem extends _ThreadItem {
  _MessageItem(this.message);
  final ChatMessageModel message;
}

class _SessionStartItem extends _ThreadItem {
  _SessionStartItem(this.session);
  final ChatSupportSessionModel session;
}

class _SessionEndItem extends _ThreadItem {
  _SessionEndItem(this.session);
  final ChatSupportSessionModel session;
}

class SupportChatView extends StatefulWidget {
  const SupportChatView({super.key});

  @override
  State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView> {
  bool _isSending = false;
  String? _presenceLabel;

  List<_ThreadItem> _buildThreadItems(ChatCubit cubit) {
    final messages = [...cubit.messages]
      ..sort((a, b) => a.sentAtUtc.compareTo(b.sentAtUtc));
    final sessions = [...cubit.supportSessions]
      ..sort((a, b) => a.assignedAtUtc.compareTo(b.assignedAtUtc));

    if (sessions.isEmpty) {
      return messages.map(_MessageItem.new).toList();
    }

    final events = <({DateTime at, int order, _ThreadItem item})>[];
    var order = 0;
    for (final session in sessions) {
      events.add((
        at: session.assignedAtUtc.toUtc(),
        order: order++,
        item: _SessionStartItem(session),
      ));
      if (!session.isActive) {
        events.add((
          at: (session.releasedAtUtc ?? session.assignedAtUtc).toUtc(),
          order: order++,
          item: _SessionEndItem(session),
        ));
      }
    }
    for (final message in messages) {
      events.add((
        at: message.sentAtUtc.toUtc(),
        order: order++,
        item: _MessageItem(message),
      ));
    }

    events.sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      if (byTime != 0) return byTime;
      return a.order.compareTo(b.order);
    });

    return events.map((e) => e.item).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).liveChat),
          backgroundColor: LightColor.defaultColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context).pleaseLoginToChatWithSupport,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.kLoginView),
                  child: Text(S.of(context).login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => ChatCubit()
        ..startSupportChat(adminUserId: ApiConstants.supportAdminUserId),
      child: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatMessageSending || state is ChatUploadingMedia) {
            setState(() => _isSending = true);
          } else if (state is ChatMessageSent ||
              state is ChatMessageSendError ||
              state is ChatMessagesLoaded) {
            setState(() => _isSending = false);
          }
          if (state is ChatPresenceUpdated || state is ChatSessionsUpdated) {
            setState(
              () => _presenceLabel = ChatCubit.get(context).presenceLabel(),
            );
          }
          if (state is ChatMessageSendError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final cubit = ChatCubit.get(context);
          final threadItems = _buildThreadItems(cubit).reversed.toList();
          final isLoading = state is ChatLoading && threadItems.isEmpty;
          final agentLabel = cubit.activeAgentName?.trim();
          final hasAgent =
              agentLabel != null && agentLabel.isNotEmpty;
          final title = hasAgent ? agentLabel : S.of(context).liveChat;
          final subtitle = hasAgent
              ? S.of(context).chatSessionActiveWith(agentLabel)
              : (_presenceLabel ??
                  cubit.presenceLabel() ??
                  S.of(context).chatWithTheSupportTeamNow);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 0.5,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: Colors.white24,
                    child: Text(
                      hasAgent
                          ? agentLabel.trim().substring(0, 1).toUpperCase()
                          : 'S',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasAgent
                                ? const Color(0xFF86EFAC)
                                : Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: LightColor.defaultColor,
            ),
            body: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state is ChatMessagesError && threadItems.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Text(state.message),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 20.h,
                              ),
                              physics: const BouncingScrollPhysics(),
                              reverse: true,
                              itemCount: threadItems.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 8.h),
                              itemBuilder: (context, index) {
                                final item = threadItems[index];
                                return switch (item) {
                                  _MessageItem(:final message) =>
                                    ChatMessageBubble(
                                      message: message,
                                      isMe: message.fromUserId == cubit.userId,
                                    ),
                                  _SessionStartItem(:final session) =>
                                    ChatSessionDivider(
                                      label: session.isActive
                                          ? S.of(context).chatSessionActiveWith(
                                              session.agentName,
                                            )
                                          : S
                                              .of(context)
                                              .chatSessionStartedWith(
                                                session.agentName,
                                              ),
                                    ),
                                  _SessionEndItem(:final session) =>
                                    ChatSessionDivider(
                                      label: S.of(context).chatSessionClosedBy(
                                            session.agentName,
                                          ),
                                    ),
                                };
                              },
                            ),
                ),
                ChatInputBar(
                  isSending: _isSending,
                  onSendText: cubit.sendTextMessage,
                  onSendImage: (path) => cubit.sendMediaMessage(
                    filePath: path,
                    messageType: ChatMessageType.image,
                  ),
                  onSendVoice: (path) => cubit.sendMediaMessage(
                    filePath: path,
                    messageType: ChatMessageType.voice,
                  ),
                  onSendVideo: (path) => cubit.sendMediaMessage(
                    filePath: path,
                    messageType: ChatMessageType.video,
                  ),
                  onSendLocation: cubit.sendLocationMessage,
                  onSendFile: (path, name) => cubit.sendFileMessage(
                    filePath: path,
                    fileName: name,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
