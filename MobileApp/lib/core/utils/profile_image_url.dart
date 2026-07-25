import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';

String? profileImageUrlFromPath(
  String? path, {
  int? revision,
}) {
  final trimmed = path?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final base = ApiConstants.resolveMediaUrl(trimmed);
  if (base.isEmpty) return null;
  final rev = revision ?? AuthService.instance.profileImageRevision.value;
  return '$base?v=$rev';
}
