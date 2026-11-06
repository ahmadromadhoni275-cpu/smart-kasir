import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'tema.dart'; 
import 'models/support_ticket_model.dart';
import 'models/support_reply_model.dart';
import 'core/services/support_ticket_service.dart';

class HalamanDetailTiket extends StatefulWidget {
  final int ticketId;

  const HalamanDetailTiket({super.key, required this.ticketId});

  @override
  State<HalamanDetailTiket> createState() => _HalamanDetailTiketState();
}

class _HalamanDetailTiketState extends State<HalamanDetailTiket> {
  final SupportTicketService _ticketService = SupportTicketService();
  final TextEditingController _replyCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  SupportTicketModel? _ticket;
  List<SupportReplyModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadTicketDetail();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetail() async {
    try {
      final data = await _ticketService.getTicketDetail(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = data['ticket'] as SupportTicketModel;
          _messages = data['messages'] as List<SupportReplyModel>;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')), 
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final success = await _ticketService.replyTicket(widget.ticketId, text);
      if (success) {
        _replyCtrl.clear();
        await _loadTicketDetail(); 
      } else {
        throw Exception('Gagal mengirim pesan.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal mengirim balasan. Coba lagi.'), 
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _closeTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primaryEmerald),
            SizedBox(width: 8),
            Text('Tutup Tiket?', style: TextStyle(color: AppColors.navyActive, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Apakah masalah Anda sudah teratasi? Tiket yang ditutup tidak dapat dibalas lagi.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        final success = await _ticketService.closeTicket(widget.ticketId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket berhasil ditutup.'), backgroundColor: AppColors.primaryEmerald));
          _loadTicketDetail(); // Refresh UI
        }
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menutup tiket.'), backgroundColor: AppColors.error));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return AppColors.error; // Butuh aksi
      case 'IN_PROGRESS': return AppColors.smartBlue;
      case 'RESOLVED': return AppColors.primaryEmerald;
      case 'CLOSED': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        title: _isLoading
            ? const Text('Memuat...', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tiket #${_ticket!.ticketId}', style: const TextStyle(color: AppColors.navyActive, fontSize: 16, fontWeight: FontWeight.w900)),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _getStatusColor(_ticket!.status), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_ticket!.subject, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
        actions: [
          if (_ticket != null && _ticket!.status != 'CLOSED')
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppColors.primaryEmerald),
              tooltip: 'Tutup Tiket (Selesai)',
              onPressed: _closeTicket,
            )
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
                    ),
                    _buildInputArea(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportReplyModel msg) {
    final bool isUser = msg.senderType == 'USER';
    final DateTime time = DateTime.parse(msg.createdAt).toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryEmerald.withOpacity(0.15),
              child: const Icon(Icons.support_agent, size: 18, color: AppColors.primaryEmerald),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.navyActive : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('Tim Dukungan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                    ),
                  Text(msg.message, style: TextStyle(color: isUser ? Colors.white : AppColors.navyActive, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(time),
                    style: TextStyle(color: isUser ? Colors.white70 : AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    if (_ticket!.status == 'CLOSED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: const Border(top: BorderSide(color: Colors.white, width: 2))),
        child: const SafeArea(
          child: Column(
            children: [
              Icon(Icons.lock, color: AppColors.textSecondary, size: 24),
              SizedBox(height: 8),
              Text('Tiket ini telah ditutup.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Silakan buat tiket baru jika ada kendala lain.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _replyCtrl,
                  minLines: 1, maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Ketik balasan Anda...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _isSending
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryEmerald)))
                : InkWell(
                    onTap: _sendReply,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(color: AppColors.primaryEmerald, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
