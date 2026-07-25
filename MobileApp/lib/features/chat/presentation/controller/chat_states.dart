import 'package:alrasmarket/features/chat/data/models/chat_message_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_presence_model.dart';
import 'package:alrasmarket/features/chat/data/models/chat_support_session_model.dart';
import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConnectionState extends ChatState {
  const ChatConnectionState(this.isConnected);
  final bool isConnected;

  @override
  List<Object?> get props => [isConnected];
}

class ChatMessagesLoaded extends ChatState {
  const ChatMessagesLoaded(this.messages);
  final List<ChatMessageModel> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatMessagesError extends ChatState {
  const ChatMessagesError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ChatMessageSending extends ChatState {}

class ChatMessageSent extends ChatState {}

class ChatMessageSendError extends ChatState {
  const ChatMessageSendError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ChatNewIncomingMessage extends ChatState {
  const ChatNewIncomingMessage(this.message);
  final ChatMessageModel message;

  @override
  List<Object?> get props => [message];
}

class ChatUploadingMedia extends ChatState {}

class ChatPresenceUpdated extends ChatState {
  const ChatPresenceUpdated(this.presence);
  final ChatPresenceModel presence;

  @override
  List<Object?> get props => [presence];
}

class ChatSessionsUpdated extends ChatState {
  const ChatSessionsUpdated(this.sessions);
  final List<ChatSupportSessionModel> sessions;

  @override
  List<Object?> get props => [sessions];
}

class ChatPassphraseRequired extends ChatState {
  const ChatPassphraseRequired({this.invalid = false});
  final bool invalid;

  @override
  List<Object?> get props => [invalid];
}
