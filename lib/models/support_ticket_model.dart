class SupportTicketModel {
  final int ticketId;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final String updatedAt;

  SupportTicketModel({
    required this.ticketId, required this.subject, required this.description,
    required this.priority, required this.status, required this.updatedAt
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      ticketId: int.tryParse(json['support_ticket_id']?.toString() ?? '0') ?? 0,
      subject: json['subject']?.toString() ?? 'Tanpa Subjek',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'OPEN',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
