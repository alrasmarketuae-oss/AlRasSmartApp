import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';

class AiChatMessage {
  AiChatMessage({
    required this.text,
    required this.isUser,
    List<String>? thinkingSteps,
    this.thinkingDurationMs,
    this.showMediaUpload = false,
    this.showSupportCallbackForm = false,
    this.supportQuestion,
    this.responseId,
    this.replyPreview,
    List<MyListingProductModel>? listings,
  })  : thinkingSteps = thinkingSteps ?? <String>[],
        listings = listings ?? <MyListingProductModel>[];

  String text;
  final bool isUser;
  final List<String> thinkingSteps;
  final int? thinkingDurationMs;
  bool showMediaUpload;
  bool showSupportCallbackForm;
  String? supportQuestion;
  final int? responseId;
  final String? replyPreview;
  List<MyListingProductModel> listings;
}
