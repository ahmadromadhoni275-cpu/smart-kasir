import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart'; // File tema Anda (AppColors)
import 'core/services/support_api_service.dart';

class HalamanRiwayatBantuan extends StatefulWidget {
  const HalamanRiwayatBantuan({super.key});

  @override
  State<HalamanRiwayatBantuan> createState() => _HalamanRiwayatBantuanState();
}

class _HalamanRiwayatBantuanState extends State<HalamanRiwayatBantuan> {
  final SupportApiService _apiService = SupportApiService();
  
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat riwayat percakapan.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        title: const Text(
          'Riwayat Bantuan AI', 
          style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRiwayat,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildListRiwayat(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat percakapan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive),
          ),
          const SizedBox(height: 8),
          const Text(
            'Percakapan Anda dengan Smart Assist\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tanya Smart Assist Sekarang', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildListRiwayat() {
    return RefreshIndicator(
      onRefresh: _loadRiwayat,
      color: AppColors.primaryEmerald,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final conv = _conversations[index];
          final bool isActive = conv['status'] == 'ACTIVE';
          final DateTime updatedAt = DateTime.parse(conv['updated_at']).toLocal();
          
          return InkWell(
            onTap: () {
              // Jika Anda ingin membuat fitur load spesifik chat, 
              // Anda bisa mengirim conversation_id ini kembali ke HalamanPusatBantuan
              Navigator.pop(context, conv['support_conversation_id']);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isActive ? AppColors.primaryEmerald.withOpacity(0.1) : AppColors.lightGray,
                    child: Icon(
                      Icons.smart_toy, 
                      color: isActive ? AppColors.primaryEmerald : AppColors.textSecondary
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv['title'] ?? 'Percakapan Baru',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(updatedAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryEmerald.withOpacity(0.1) : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActive ? 'Aktif' : 'Selesai',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.primaryEmerald : AppColors.textSecondary,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
