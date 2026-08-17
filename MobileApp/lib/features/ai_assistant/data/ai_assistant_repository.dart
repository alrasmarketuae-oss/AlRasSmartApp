import 'package:alrasmarket/core/error/failure.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class AiConversationSummary {
  const AiConversationSummary({
    required this.id,
    required this.clientSessionId,
    required this.titlePreview,
    required this.lastMessageAtUtc,
    required this.messageCount,
  });

  final String id;
  final String clientSessionId;
  final String? titlePreview;
  final String lastMessageAtUtc;
  final int messageCount;

  factory AiConversationSummary.fromJson(Map<String, dynamic> json) {
    return AiConversationSummary(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      clientSessionId: json['clientSessionId']?.toString() ??
          json['ClientSessionId']?.toString() ??
          '',
      titlePreview: json['titlePreview']?.toString() ??
          json['TitlePreview']?.toString(),
      lastMessageAtUtc: json['lastMessageAtUtc']?.toString() ??
          json['LastMessageAtUtc']?.toString() ??
          '',
      messageCount: json['messageCount'] as int? ??
          json['MessageCount'] as int? ??
          0,
    );
  }
}

class AiConversationMessageModel {
  const AiConversationMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAtUtc,
    this.listings = const [],
    this.thinkingSteps = const [],
  });

  final int id;
  final String role;
  final String content;
  final String createdAtUtc;
  final List<dynamic> listings;
  final List<String> thinkingSteps;

  factory AiConversationMessageModel.fromJson(Map<String, dynamic> json) {
    final rawListings = json['listings'] ?? json['Listings'];
    final rawThinking = json['thinkingSteps'] ?? json['ThinkingSteps'];
    return AiConversationMessageModel(
      id: json['id'] as int? ?? json['Id'] as int? ?? 0,
      role: (json['role'] ?? json['Role'] ?? 'user').toString(),
      content: json['content']?.toString() ?? json['Content']?.toString() ?? '',
      createdAtUtc: json['createdAtUtc']?.toString() ??
          json['CreatedAtUtc']?.toString() ??
          '',
      listings: rawListings is List ? List<dynamic>.from(rawListings) : const [],
      thinkingSteps: rawThinking is List
          ? rawThinking
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

class AiConversationMessagesPage {
  const AiConversationMessagesPage({
    required this.messages,
    required this.hasMore,
    this.nextBeforeMessageId,
  });

  final List<AiConversationMessageModel> messages;
  final bool hasMore;
  final int? nextBeforeMessageId;

  factory AiConversationMessagesPage.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'] ?? json['Messages'] ?? [];
    final messages = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (item) => AiConversationMessageModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <AiConversationMessageModel>[];
    final next = json['nextBeforeMessageId'] ?? json['NextBeforeMessageId'];
    return AiConversationMessagesPage(
      messages: messages,
      hasMore: json['hasMore'] == true || json['HasMore'] == true,
      nextBeforeMessageId: next is num ? next.toInt() : int.tryParse('$next'),
    );
  }
}

class AiConversationListPage {
  const AiConversationListPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<AiConversationSummary> items;
  final int page;
  final int totalPages;

  factory AiConversationListPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['Items'] ?? [];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (item) => AiConversationSummary.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <AiConversationSummary>[];
    return AiConversationListPage(
      items: items,
      page: json['page'] as int? ?? json['Page'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? json['TotalPages'] as int? ?? 1,
    );
  }
}

class AiAssistantRepository {
  Future<Either<Failure, AiConversationListPage>> listConversations({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.aiAssistantConversationsEndPoint,
        query: {'page': page, 'pageSize': pageSize},
        token: token,
      );
      if (response?.statusCode != 200 || response?.data is! Map) {
        return const Left(ServerFailure('Failed to load AI conversations'));
      }
      return Right(
        AiConversationListPage.fromJson(
          Map<String, dynamic>.from(response!.data as Map),
        ),
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.response?.data?.toString() ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to load AI conversations: $e'));
    }
  }

  Future<Either<Failure, AiConversationMessagesPage>> getConversationMessages({
    required String token,
    required String conversationId,
    int limit = 50,
    int? beforeMessageId,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: ApiConstants.aiAssistantConversationMessagesEndPoint(
          conversationId,
        ),
        query: {
          'limit': limit,
          if (beforeMessageId != null) 'before': beforeMessageId,
        },
        token: token,
      );
      if (response?.statusCode != 200 || response?.data is! Map) {
        return const Left(ServerFailure('Failed to load AI messages'));
      }
      return Right(
        AiConversationMessagesPage.fromJson(
          Map<String, dynamic>.from(response!.data as Map),
        ),
      );
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.response?.data?.toString() ?? e.message ?? 'Network error',
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to load AI messages: $e'));
    }
  }
}
