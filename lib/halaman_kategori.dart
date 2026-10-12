import 'package:flutter/material.dart';
import 'core/services/category_service.dart';
import 'models/category_model.dart';
import 'tema.dart';

class HalamanKategori extends StatefulWidget {
  const HalamanKategori({super.key});

  @override
  State<HalamanKategori> createState() => _HalamanKategoriState();
}

class _HalamanKategoriState extends State<HalamanKategori> {
  final CategoryService _service = CategoryService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getCategories(search: _searchCtrl.text.trim());
      setState(() => _categories = result);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: warna, behavior: SnackBarBehavior.floating));

  Future<void> _hapusKategori(Category category) async {
    if (category.productCount > 0) {
      _showNotif('Tidak bisa dihapus! Dipakai oleh ${category.productCount} produk.', Colors.orange);
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Anda yakin ingin menghapus kategori "${category.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _service.deleteCategory(category.categoryId);
      _showNotif('Kategori berhasil dihapus', AppColors.greenAccent);
      _fetchCategories();
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // FORM TAMBAH / EDIT KATEGORI
  // ==========================================
  void _tampilFormKategori({Category? category}) {
    final bool isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    String status = category?.status ?? 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isEdit ? Icons.edit_note : Icons.add_circle, color: AppColors.primaryEmerald, size: 28),
                    const SizedBox(width: 12),
                    Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'Nama Kategori *', prefixIcon: const Icon(Icons.category), filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(labelText: 'Status', prefixIcon: const Icon(Icons.toggle_on), filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Aktif')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('Tidak Aktif')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => status = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        _showNotif('Nama kategori tidak boleh kosong', AppColors.error);
                        return;
                      }
                      
                      Navigator.pop(context); // Tutup form
                      setState(() => _isLoading = true);

                      try {
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'status': status
                        };

                        if (isEdit) {
                          await _service.updateCategory(category.categoryId, data);
                          _showNotif('Kategori diperbarui', AppColors.greenAccent);
                        } else {
                          await _service.createCategory(data);
                          _showNotif('Kategori ditambahkan', AppColors.greenAccent);
                        }
                        _fetchCategories(); 
                      } catch (e) {
                        _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
                        setState(() => _isLoading = false);
                      }
                    },
                    child: const Text('SIMPAN KATEGORI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kategori Produk', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilFormKategori(),
        backgroundColor: AppColors.primaryEmerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Kategori Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari kategori...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.refresh, color: AppColors.primaryEmerald), onPressed: _fetchCategories),
                filled: true,
                fillColor: AppColors.lightGray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _fetchCategories(),
            ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('${_categories.length} Kategori Ditemukan', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),

          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : RefreshIndicator(
                  color: AppColors.primaryEmerald,
                  onRefresh: _fetchCategories,
                  child: _categories.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          const Icon(Icons.category_outlined, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Belum ada kategori.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final bool isActive = cat.status == 'ACTIVE';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: isActive ? AppColors.primaryEmerald.withOpacity(0.1) : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.category, color: isActive ? AppColors.primaryEmerald : Colors.grey),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(cat.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? AppColors.navyActive : Colors.grey))),
                                  if (!isActive)
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)), child: const Text('INACTIVE', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)))
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(6)),
                                  child: Text('${cat.productCount} Produk terhubung', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (value) {
                                  if (value == 'edit') _tampilFormKategori(category: cat);
                                  if (value == 'hapus') _hapusKategori(cat);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Edit Kategori')])),
                                  const PopupMenuItem(value: 'hapus', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus')])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
          ),
        ],
      ),
    );
  }
}
