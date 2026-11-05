import 'dart:ui';
import 'package:flutter/material.dart';

import 'tema.dart';
import 'models/user_model.dart';
import 'core/services/user_service.dart';
import 'halaman_tambah_pengguna.dart';

class HalamanPengguna extends StatefulWidget {
  const HalamanPengguna({super.key});

  @override
  State<HalamanPengguna> createState() => _HalamanPenggunaState();
}

class _HalamanPenggunaState extends State<HalamanPengguna> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<UserModel> _users = [];
  String _filterRole = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUsers(search: _searchCtrl.text, role: _filterRole);
      setState(() => _users = users);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  void _showNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: warna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }
  }

  Future<void> _toggleStatus(UserModel user) async {
    final newStatus = user.isActive ? 'INACTIVE' : 'ACTIVE';
    final actionText = user.isActive ? 'menonaktifkan' : 'mengaktifkan';
    
    // Popup Konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Akses', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        content: Text('Anda yakin ingin $actionText akses untuk ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: user.isActive ? AppColors.error : AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _userService.updateAccess(user.userId, {'status': newStatus});
      _fetchUsers();
      _showNotif('Status akses berhasil diperbarui', AppColors.primaryEmerald);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
  }

  Color _getRoleColor(String role) {
    if (role == 'OWNER') return Colors.purple.shade700;
    if (role == 'MANAGER') return AppColors.smartBlue;
    return AppColors.primaryEmerald;
  }

  Widget _buildGlassFilterChip(String label, String value) {
    bool isSelected = _filterRole == value;
    return InkWell(
      onTap: () {
        setState(() => _filterRole = value);
        _fetchUsers();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyActive : Colors.white.withOpacity(0.5),
          border: Border.all(color: isSelected ? AppColors.navyActive : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Karyawan & Akses', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryEmerald,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanTambahPengguna())).then((_) => _fetchUsers()),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Tambah Karyawan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        elevation: 4,
      ),
      body: Stack(
        children: [
          // Background Gradient (Crystal UI)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
              ),
            ),
          ),

          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              
              // Filter Panel Glass
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau email...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                            filled: true, fillColor: Colors.white.withOpacity(0.7),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onSubmitted: (_) => _fetchUsers(),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildGlassFilterChip('Semua Peran', ''),
                              _buildGlassFilterChip('Owner', 'OWNER'),
                              _buildGlassFilterChip('Manajer', 'MANAGER'),
                              _buildGlassFilterChip('Kasir', 'KASIR'),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                    : _users.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), // bottom padding for FAB
                            physics: const BouncingScrollPhysics(),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final u = _users[index];
                              Color roleColor = _getRoleColor(u.role);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                                  boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: roleColor.withOpacity(0.15),
                                        child: Icon(Icons.person, color: roleColor, size: 28),
                                      ),
                                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 16)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(u.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: roleColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                                child: Text(u.role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: roleColor)),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: u.isActive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                                child: Text(u.isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: u.isActive ? Colors.green.shade700 : Colors.red.shade700)),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        onSelected: (val) {
                                          if (val == 'status') _toggleStatus(u);
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'status', 
                                            child: Row(
                                              children: [
                                                Icon(u.isActive ? Icons.block : Icons.check_circle_outline, color: u.isActive ? AppColors.error : AppColors.primaryEmerald, size: 20),
                                                const SizedBox(width: 8),
                                                Text(u.isActive ? 'Nonaktifkan Akses' : 'Aktifkan Akses'),
                                              ],
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.group_off_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          const Text('Tidak ada data karyawan.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
