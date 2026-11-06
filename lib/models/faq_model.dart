class FaqModel {
  final int faqId;
  final String category;
  final String question;
  final String answer;

  FaqModel({required this.faqId, required this.category, required this.question, required this.answer});

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      faqId: int.tryParse(json['support_faq_id']?.toString() ?? '0') ?? 0,
      category: json['category']?.toString() ?? 'UMUM',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }
}
