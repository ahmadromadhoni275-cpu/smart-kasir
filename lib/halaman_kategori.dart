import 'dart:ui';
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

  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
      backgroundColor: warna, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
    )
  );

  Future<void> _hapusKategori(Category category) async {
    if (category.productCount > 0) {
      _showNotif('Gagal dihapus! Kategori masih dipakai oleh ${category.productCount} produk.', AppColors.error);
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline, color: AppColors.error, size: 40)),
                  const SizedBox(height: 16),
                  const Text('Hapus Kategori?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                  const SizedBox(height: 8),
                  Text('Anda yakin ingin menghapus kategori "${category.name}"?', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                      Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Hapus', style: TextStyle(color: Colors.white)))),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _service.deleteCategory(category.categoryId);
      _showNotif('Kategori berhasil dihapus', AppColors.primaryEmerald);
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
          bool isActive = status == 'ACTIVE';

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5)))),
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: Icon(isEdit ? Icons.edit_note : Icons.category_outlined, color: AppColors.smartBlue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori *', 
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.drive_file_rename_outline, color: AppColors.smartBlue), 
                        filled: true, fillColor: Colors.white.withOpacity(0.7), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.smartBlue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 1.5)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status Kategori Aktif', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 15)),
                          Switch(
                            value: isActive,
                            activeColor: AppColors.primaryEmerald,
                            onChanged: (val) => setModalState(() => status = val ? 'ACTIVE' : 'INACTIVE'),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald, 
                          elevation: 5,
                          shadowColor: AppColors.primaryEmerald.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            _showNotif('Nama kategori tidak boleh kosong', AppColors.warning);
                            return;
                          }
                          
                          Navigator.pop(context); 
                          setState(() => _isLoading = true);

                          try {
                            final data = {
                              'name': nameCtrl.text.trim(),
                              'status': status
                            };

                            if (isEdit) {
                              await _service.updateCategory(category!.categoryId, data);
                              _showNotif('Kategori berhasil diperbarui', AppColors.primaryEmerald);
                            } else {
                              await _service.createCategory(data);
                              _showNotif('Kategori berhasil ditambahkan', AppColors.primaryEmerald);
                            }
                            _fetchCategories(); 
                          } catch (e) {
                            _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
                            setState(() => _isLoading = false);
                          }
                        },
                        child: const Text('SIMPAN KATEGORI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kategori Produk', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.withOpacity(0.2), height: 1)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilFormKategori(),
        backgroundColor: AppColors.primaryEmerald,
        elevation: 8,
        shadowColor: AppColors.primaryEmerald.withOpacity(0.4),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Kategori Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Background Gradient (Crystal UI Vibe)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]
              ),
            ),
          ),

          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              
              // Top Action Panel
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.4)))),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari kategori...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.smartBlue),
                            filled: true, fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onSubmitted: (_) => _fetchCategories(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_categories.length} Kategori Ditemukan', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                            InkWell(
                              onTap: _fetchCategories,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                  children: [Icon(Icons.refresh, size: 14, color: AppColors.smartBlue), SizedBox(width: 4), Text('Segarkan', style: TextStyle(fontSize: 12, color: AppColors.smartBlue, fontWeight: FontWeight.bold))],
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Category List
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : RefreshIndicator(
                      color: AppColors.primaryEmerald,
                      backgroundColor: Colors.white,
                      onRefresh: _fetchCategories,
                      child: _categories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.category_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                const Text('Belum ada data kategori.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final bool isActive = cat.status == 'ACTIVE';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(isActive ? 0.7 : 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                                  boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      leading: Container(
                                        width: 50, height: 50,
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.smartBlue.withOpacity(0.15) : Colors.grey.withOpacity(0.15), 
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: isActive ? AppColors.smartBlue.withOpacity(0.3) : Colors.transparent)
                                        ),
                                        child: Icon(Icons.category_outlined, color: isActive ? AppColors.smartBlue : Colors.grey, size: 26),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(child: Text(cat.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? AppColors.navyActive : AppColors.textSecondary))),
                                          if (!isActive)
                                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Text('NONAKTIF', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900)))
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: AppColors.lightGray.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
                                                  const SizedBox(width: 6),
                                                  Text('${cat.productCount} Produk terhubung', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        color: Colors.white.withOpacity(0.95),
                                        elevation: 8,
                                        onSelected: (value) {
                                          if (value == 'edit') _tampilFormKategori(category: cat);
                                          if (value == 'hapus') _hapusKategori(cat);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppColors.smartBlue), SizedBox(width: 12), Text('Edit', style: TextStyle(fontWeight: FontWeight.w500))])),
                                          const PopupMenuItem(value: 'hapus', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.error), SizedBox(width: 12), Text('Hapus', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error))])),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
