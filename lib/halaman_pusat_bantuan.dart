import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'tema.dart'; // File tema yang berisi AppColors
import 'core/services/support_api_service.dart'; // Import service API

// Model untuk menampung data pesan di UI
class SupportMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? actionLabel; 
  final String? actionRoute; 
  bool? isHelpful; 

  SupportMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionLabel,
    this.actionRoute,
    this.isHelpful,
  });
}

class HalamanPusatBantuan extends StatefulWidget {
  const HalamanPusatBantuan({super.key});

  @override
  State<HalamanPusatBantuan> createState() => _HalamanPusatBantuanState();
}

class _HalamanPusatBantuanState extends State<HalamanPusatBantuan> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final SupportApiService _apiService = SupportApiService();
  
  bool _isTyping = false;
  bool _isInitializing = true;
  int? _activeConversationId;

  final List<SupportMessage> _messages = [];

  final List<String> _quickQuestions = [
    'Cara melakukan transaksi',
    'Bagaimana mengatur stok produk?',
    'Cara menutup shift kasir',
    'Printer tidak berfungsi',
    'Laporan keuntungan'
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // INISIALISASI PERCAKAPAN (Ambil dari API)
  Future<void> _initializeChat() async {
    setState(() => _isInitializing = true);
    
    try {
      final convs = await _apiService.getConversations();
      
      if (convs.isNotEmpty && convs.first['status'] == 'ACTIVE') {
        _activeConversationId = int.parse(convs.first['support_conversation_id'].toString());
        
        final history = await _apiService.getMessages(_activeConversationId!);
        
        if (mounted) {
          setState(() {
            _messages.clear();
            for (var msg in history) {
              _messages.add(SupportMessage(
                id: msg['support_message_id'].toString(),
                text: msg['message'],
                isUser: msg['sender_type'] == 'USER',
                timestamp: DateTime.parse(msg['created_at']).toLocal(),
                actionLabel: msg['action_route'] != null ? 'Buka Halaman' : null,
                actionRoute: msg['action_route'],
              ));
            }
          });
        }
      } else {
        _activeConversationId = await _apiService.startConversation();
        if (mounted) {
          setState(() {
            _messages.add(
              SupportMessage(
                id: 'welcome',
                text: 'Halo! 👋 Saya Smart Assist.\n\nSaya bisa membantu Anda memahami fitur, mengatasi kendala, dan menemukan menu yang dibutuhkan di Smart Kasir.\n\nApa yang ingin Anda tanyakan hari ini?',
                isUser: false,
                timestamp: DateTime.now(),
              )
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error init chat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal terhubung ke server bantuan.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
      _scrollToBottom();
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

  // MENGIRIM PESAN (Panggil API Backend)
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _activeConversationId == null) return;

    final String userText = text.trim();
    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.add(
        SupportMessage(
          id: tempId,
          text: userText,
          isUser: true,
          timestamp: DateTime.now(),
        )
      );
      _messageCtrl.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final aiResponse = await _apiService.sendMessage(_activeConversationId!, userText);
      
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            SupportMessage(
              id: aiResponse['support_message_id'].toString(),
              text: aiResponse['message'],
              isUser: false,
              timestamp: DateTime.parse(aiResponse['created_at']).toLocal(),
              actionLabel: aiResponse['action_route'] != null ? 'Buka Halaman' : null,
              actionRoute: aiResponse['action_route'],
            )
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(SupportMessage(
            id: 'err_${DateTime.now().millisecondsSinceEpoch}',
            text: 'Maaf, gagal terhubung ke server Smart Assist. Silakan periksa koneksi internet Anda.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  // MENGIRIM FEEDBACK (Jempol)
  Future<void> _giveFeedback(SupportMessage message, bool isHelpful) async {
    if (message.id.startsWith('temp_') || message.id.startsWith('err_') || message.id == 'welcome') return;
    
    setState(() => message.isHelpful = isHelpful);
    
    try {
      await _apiService.submitFeedback(int.parse(message.id), isHelpful ? 1 : 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih atas masukannya!', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.navyActive,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal kirim feedback: $e");
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jawaban berhasil disalin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primaryEmerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isInitializing 
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
                      
                      bool showDateHeader = false;
                      if (index == 0) {
                        showDateHeader = true;
                      } else {
                        final prevMsg = _messages[index - 1];
                        if (msg.timestamp.day != prevMsg.timestamp.day) {
                          showDateHeader = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateHeader) _buildDateHeader(msg.timestamp),
                          _buildChatBubble(msg),
                        ],
                      );
                    },
                  ),
                ),
                
                if (_isTyping)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryEmerald.withOpacity(0.2),
                          child: const Icon(Icons.smart_toy, size: 14, color: AppColors.primaryEmerald),
                        ),
                        const SizedBox(width: 8),
                        const Text('Smart Assist sedang memikirkan jawaban...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),

                if (!_isTyping && _messages.length < 5) _buildQuickQuestions(),

                _buildInputArea(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.navyActive,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: const Icon(Icons.smart_toy, color: AppColors.primaryEmerald, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Smart Assist', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryEmerald, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Tersedia (AI Online)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment),
          tooltip: 'Mulai Ulang Percakapan',
          onPressed: () {
            // Memaksa membuat sesi baru dengan mereset id
            _activeConversationId = null;
            _initializeChat();
          },
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(12)),
          child: Text(
            DateFormat('dd MMMM yyyy', 'id_ID').format(date),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ),
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryEmerald.withOpacity(0.15),
              child: const Icon(Icons.smart_toy, size: 18, color: AppColors.primaryEmerald),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryEmerald : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  
                  // TOMBOL NAVIGASI MENU (Action Route)
                  if (!isMe && msg.actionRoute != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Buka halaman sesuai route yang diberikan AI
                          Navigator.pushNamed(context, msg.actionRoute!);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyActive,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(msg.actionLabel ?? 'Buka Halaman'),
                      ),
                    )
                  ],

                  const SizedBox(height: 8),
                  
                  // INFO WAKTU & FEEDBACK
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      
                      if (!isMe && !msg.id.startsWith('err_') && msg.id != 'welcome') ...[
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => _copyToClipboard(msg.text),
                          child: const Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => _giveFeedback(msg, true),
                          child: Icon(
                            msg.isHelpful == true ? Icons.thumb_up : Icons.thumb_up_alt_outlined, 
                            size: 14, 
                            color: msg.isHelpful == true ? AppColors.primaryEmerald : AppColors.textSecondary
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => _giveFeedback(msg, false),
                          child: Icon(
                            msg.isHelpful == false ? Icons.thumb_down : Icons.thumb_down_alt_outlined, 
                            size: 14, 
                            color: msg.isHelpful == false ? AppColors.error : AppColors.textSecondary
                          ),
                        ),
                      ]
                    ],
                  ),
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
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(_quickQuestions[index], style: const TextStyle(fontSize: 12, color: AppColors.navyActive)),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _sendMessage(_quickQuestions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _messageCtrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pertanyaan Anda di sini...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Container(
              decoration: const BoxDecoration(color: AppColors.navyActive, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(_messageCtrl.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
