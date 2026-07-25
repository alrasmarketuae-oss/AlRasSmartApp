class ApiErrorModel {
  final String? status;
  final int? code;
  final String? message;
  final String? error;
  const ApiErrorModel({this.status, this.message, this.code, this.error});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status,
    'code': code,
    'message': message,
    'error': error,
  };
  static ApiErrorModel fromJson(Map<String, dynamic> json) => ApiErrorModel(
    status: json['status'] as String?,
    code: (json['code'] as num?)?.toInt(),
    message: json['message'] as String?,
    error: json['error'] as String?,
  );
}
