import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'tema.dart'; 
import 'core/services/help_service.dart'; 
import 'halaman_riwayat_bantuan.dart'; 
import 'halaman_daftar_tiket_bantuan.dart';

class SupportMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? actionLabel; 
  final String? actionRoute; 
  bool? isHelpful; 

  SupportMessage({required this.id, required this.text, required this.isUser, required this.timestamp, this.actionLabel, this.actionRoute, this.isHelpful});
}

class HalamanPusatBantuan extends StatefulWidget {
  const HalamanPusatBantuan({super.key});

  @override
  State<HalamanPusatBantuan> createState() => _HalamanPusatBantuanState();
}

class _HalamanPusatBantuanState extends State<HalamanPusatBantuan> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final HelpService _apiService = HelpService();
  
  bool _isTyping = false;
  bool _isInitializing = true;
  int? _activeConversationId;

  final List<SupportMessage> _messages = [];

  final List<String> _quickQuestions = [
    'Cara transaksi kasir', 'Tutup shift kasir', 'Printer error', 'Laporan laba rugi'
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _isInitializing = true);
    try {
      if (_activeConversationId == null) {
        final convs = await _apiService.getConversations();
        if (convs.isNotEmpty && convs.first['status'] == 'ACTIVE') {
          _activeConversationId = int.parse(convs.first['support_conversation_id'].toString());
        }
      }
      
      if (_activeConversationId != null) {
        final history = await _apiService.getMessages(_activeConversationId!);
        if (mounted) {
          setState(() {
            _messages.clear();
            for (var msg in history) {
              _messages.add(SupportMessage(
                id: msg['support_message_id'].toString(), text: msg['message'], isUser: msg['sender_type'] == 'USER',
                timestamp: DateTime.parse(msg['created_at']).toLocal(), actionLabel: msg['action_route'] != null ? 'Buka Halaman' : null, actionRoute: msg['action_route'],
              ));
            }
          });
        }
      } else {
        _activeConversationId = await _apiService.startConversation();
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.add(SupportMessage(id: 'welcome', text: 'Halo! 👋 Saya Smart Assist AI.\n\nSaya siap membantu Anda memahami fitur dan mengatasi kendala di aplikasi. Apa yang bisa saya bantu hari ini?', isUser: false, timestamp: DateTime.now()));
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server bantuan.'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isInitializing = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _activeConversationId == null) return;

    final String userText = text.trim();
    setState(() {
      _messages.add(SupportMessage(id: 'temp_${DateTime.now().millisecondsSinceEpoch}', text: userText, isUser: true, timestamp: DateTime.now()));
      _messageCtrl.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final aiResponse = await _apiService.sendMessage(_activeConversationId!, userText);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(SupportMessage(
            id: aiResponse['support_message_id'].toString(), text: aiResponse['message'], isUser: false,
            timestamp: DateTime.parse(aiResponse['created_at']).toLocal(), actionLabel: aiResponse['action_route'] != null ? 'Buka Halaman' : null, actionRoute: aiResponse['action_route'],
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(SupportMessage(id: 'err', text: 'Maaf, koneksi ke Smart Assist gagal. Silakan coba lagi nanti.', isUser: false, timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
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
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: AppColors.primaryEmerald.withOpacity(0.15), child: const Icon(Icons.smart_toy, color: AppColors.primaryEmerald, size: 18)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart Assist', style: TextStyle(color: AppColors.navyActive, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryEmerald, shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Online (AI)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))]),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.assignment_outlined), tooltip: 'Tiket Bantuan', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanDaftarTiket()))),
          IconButton(
            icon: const Icon(Icons.history), tooltip: 'Riwayat Chat',
            onPressed: () async {
              final selectedConvId = await Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanRiwayatBantuan()));
              if (selectedConvId != null && selectedConvId != _activeConversationId) {
                _activeConversationId = int.parse(selectedConvId.toString());
                _initializeChat(); 
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          
          _isInitializing 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildChatBubble(_messages[index]);
                      },
                    ),
                  ),
                  if (_isTyping)
                    Padding(padding: const EdgeInsets.only(left: 16, bottom: 8), child: Row(children: [CircleAvatar(radius: 12, backgroundColor: AppColors.primaryEmerald.withOpacity(0.2), child: const Icon(Icons.smart_toy, size: 14, color: AppColors.primaryEmerald)), const SizedBox(width: 8), const Text('Smart Assist sedang mengetik...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic))])),
                  if (!_isTyping && _messages.length < 4) _buildQuickQuestions(),
                  _buildInputArea(),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(SupportMessage msg) {
    bool isMe = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 14, backgroundColor: AppColors.primaryEmerald.withOpacity(0.15), child: const Icon(Icons.smart_toy, size: 16, color: AppColors.primaryEmerald)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe ? AppColors.navyActive : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                border: isMe ? null : Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text, style: TextStyle(color: isMe ? Colors.white : AppColors.navyActive, fontSize: 14, height: 1.4)),
                  if (!isMe && msg.actionRoute != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, msg.actionRoute!), style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryEmerald, side: const BorderSide(color: AppColors.primaryEmerald), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(msg.actionLabel ?? 'Buka Halaman', style: const TextStyle(fontWeight: FontWeight.bold))))
                  ],
                  const SizedBox(height: 8),
                  Text(DateFormat('HH:mm').format(msg.timestamp), style: TextStyle(color: isMe ? Colors.white70 : AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      height: 40, margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _quickQuestions.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(_quickQuestions[index], style: const TextStyle(fontSize: 12, color: AppColors.navyActive, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white.withOpacity(0.7), side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _sendMessage(_quickQuestions[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
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
                  controller: _messageCtrl,
                  decoration: const InputDecoration(hintText: 'Tulis pesan Anda...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _sendMessage(_messageCtrl.text),
              child: Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(color: AppColors.primaryEmerald, shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
