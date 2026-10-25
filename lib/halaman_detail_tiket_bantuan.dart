import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart'; // AppColors
import 'core/services/support_api_service.dart';

class HalamanDetailTiket extends StatefulWidget {
  final int ticketId;

  const HalamanDetailTiket({super.key, required this.ticketId});

  @override
  State<HalamanDetailTiket> createState() => _HalamanDetailTiketState();
}

class _HalamanDetailTiketState extends State<HalamanDetailTiket> {
  final SupportApiService _apiService = SupportApiService();
  final TextEditingController _replyCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadTicketDetail();
  }

  Future<void> _loadTicketDetail() async {
    try {
      final data = await _apiService.getTicketDetail(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = data['ticket'];
          _messages = data['messages'];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat tiket.'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _apiService.replyTicket(widget.ticketId, _replyCtrl.text.trim());
      _replyCtrl.clear();
      await _loadTicketDetail(); // Refresh pesan
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim balasan.'), backgroundColor: AppColors.error));
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return AppColors.primaryEmerald;
      case 'IN_PROGRESS': return Colors.blue;
      case 'RESOLVED': return Colors.green;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        title: _isLoading
            ? const Text('Memuat...', style: TextStyle(color: AppColors.navyActive))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiket #${_ticket!['support_ticket_id']}', 
                      style: const TextStyle(color: AppColors.navyActive, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    _ticket!['subject'],
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
        actions: [
          if (_ticket != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text(_ticket!['status'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: _getStatusColor(_ticket!['status']),
                padding: EdgeInsets.zero,
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final bool isUser = msg['sender_type'] == 'USER';
                      final DateTime time = DateTime.parse(msg['created_at']).toLocal();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.navyActive.withOpacity(0.1),
                                child: const Icon(Icons.support_agent, size: 18, color: AppColors.navyActive),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.navyActive : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: isUser ? null : Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text('Tim Dukungan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                                      ),
                                    Text(msg['message'], style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM, HH:mm').format(time),
                                      style: TextStyle(color: isUser ? Colors.white70 : AppColors.textSecondary, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Form Input (Hanya tampil jika tiket belum ditutup)
                if (_ticket!['status'] != 'CLOSED')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyCtrl,
                              minLines: 1, maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Ketik balasan Anda...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                filled: true, fillColor: AppColors.lightGray,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSending
                              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                              : CircleAvatar(
                                  backgroundColor: AppColors.primaryEmerald,
                                  child: IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                    onPressed: _sendReply,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.lightGray,
                    child: const SafeArea(
                      child: Text('Tiket ini sudah ditutup.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
    );
  }
}
