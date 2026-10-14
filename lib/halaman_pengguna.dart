import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/pengguna_service.dart';
import 'halaman_tambah_pengguna.dart';

class HalamanPengguna extends StatefulWidget {
  const HalamanPengguna({super.key});

  @override
  State<HalamanPengguna> createState() => _HalamanPenggunaState();
}

class _HalamanPenggunaState extends State<HalamanPengguna> {
  bool _isLoading = true;
  List<dynamic> _users = [];
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
      final users = await PenggunaService.getPengguna(search: _searchCtrl.text, role: _filterRole);
      setState(() => _users = users);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(color: Colors.white)), backgroundColor: warna));
  }

  Future<void> _toggleStatus(int userId, String currentStatus) async {
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    try {
      await PenggunaService.updateAkses(userId, {'status': newStatus});
      _fetchUsers();
      _showNotif('Status berhasil diperbarui', AppColors.primaryEmerald);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
  }

  Color _getRoleColor(String role) {
    if (role == 'OWNER') return Colors.purple;
    if (role == 'MANAGER') return Colors.blue;
    return AppColors.primaryEmerald;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Karyawan & Akses', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryEmerald,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanTambahPengguna())).then((_) => _fetchUsers()),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Tambah Karyawan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true, fillColor: AppColors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _fetchUsers(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua Peran', ''),
                      const SizedBox(width: 8),
                      _buildFilterChip('Owner', 'OWNER'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Manajer', 'MANAGER'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Kasir', 'KASIR'),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                : _users.isEmpty
                    ? const Center(child: Text('Tidak ada data karyawan.', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final u = _users[index];
                          final bool isActive = u['status'] == 'ACTIVE';
                          
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: _getRoleColor(u['role']).withOpacity(0.1),
                                child: Icon(Icons.person, color: _getRoleColor(u['role'])),
                              ),
                              title: Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 16)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(u['email'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: _getRoleColor(u['role']).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                        child: Text(u['role'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(u['role']))),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: isActive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                        child: Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'status') _toggleStatus(int.parse(u['user_id'].toString()), u['status']);
                                  // Navigasi ke Detail/Hak Akses bisa ditambahkan di sini
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(value: 'status', child: Text(isActive ? 'Nonaktifkan Akses' : 'Aktifkan Akses')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterRole == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primaryEmerald,
      backgroundColor: AppColors.lightGray,
      showCheckmark: false,
      onSelected: (val) {
        if (val) {
          setState(() => _filterRole = value);
          _fetchUsers();
        }
      },
    );
  }
}
