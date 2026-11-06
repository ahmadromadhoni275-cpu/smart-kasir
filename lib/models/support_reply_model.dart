class SupportReplyModel {
  final int messageId;
  final String senderType; // 'USER' atau 'ADMIN'
  final String message;
  final String? attachmentUrl;
  final String createdAt;

  SupportReplyModel({
    required this.messageId, required this.senderType, required this.message,
    this.attachmentUrl, required this.createdAt
  });

  factory SupportReplyModel.fromJson(Map<String, dynamic> json) {
    return SupportReplyModel(
      messageId: int.tryParse(json['support_ticket_message_id']?.toString() ?? '0') ?? 0,
      senderType: json['sender_type']?.toString() ?? 'USER',
      message: json['message']?.toString() ?? '',
      attachmentUrl: json['attachment_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
