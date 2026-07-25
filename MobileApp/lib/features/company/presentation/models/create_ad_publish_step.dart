import 'package:alrasmarket/generated/l10n.dart';

/// Publish pipeline steps shown on the Create Ad progress screen.
enum CreateAdPublishStep {
  idle,
  creatingAd,
  preparingImages,
  uploadingImages,
  preparingVideo,
  uploadingVideo,
  uploadingDocuments,
  finishing,
}

extension CreateAdPublishStepX on CreateAdPublishStep {
  bool get isActive => this != CreateAdPublishStep.idle;

  String label(S s, {int? percent}) {
    switch (this) {
      case CreateAdPublishStep.idle:
        return '';
      case CreateAdPublishStep.creatingAd:
        return s.publishStepCreatingAd;
      case CreateAdPublishStep.preparingImages:
        return s.publishStepPreparingImages;
      case CreateAdPublishStep.uploadingImages:
        return s.publishStepUploadingImages;
      case CreateAdPublishStep.preparingVideo:
        return s.publishStepPreparingVideo(percent ?? 0);
      case CreateAdPublishStep.uploadingVideo:
        return s.publishStepUploadingVideo;
      case CreateAdPublishStep.uploadingDocuments:
        return s.publishStepUploadingDocuments;
      case CreateAdPublishStep.finishing:
        return s.publishStepFinishing;
    }
  }

  /// Checklist rows for the progress UI, filtered by attached media.
  static List<CreateAdPublishStep> visibleChecklist({
    required bool hasImages,
    required bool hasVideo,
    required bool hasDocuments,
  }) {
    return [
      CreateAdPublishStep.creatingAd,
      if (hasImages) CreateAdPublishStep.preparingImages,
      if (hasImages) CreateAdPublishStep.uploadingImages,
      if (hasVideo) CreateAdPublishStep.preparingVideo,
      if (hasVideo) CreateAdPublishStep.uploadingVideo,
      if (hasDocuments) CreateAdPublishStep.uploadingDocuments,
      CreateAdPublishStep.finishing,
    ];
  }

  int get sortIndex {
    const order = [
      CreateAdPublishStep.creatingAd,
      CreateAdPublishStep.preparingImages,
      CreateAdPublishStep.uploadingImages,
      CreateAdPublishStep.preparingVideo,
      CreateAdPublishStep.uploadingVideo,
      CreateAdPublishStep.uploadingDocuments,
      CreateAdPublishStep.finishing,
    ];
    final i = order.indexOf(this);
    return i < 0 ? 0 : i;
  }
}
