import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart';

class HalamanStruk extends StatelessWidget {
  final Map<String, dynamic> data;

  const HalamanStruk({super.key, required this.data});

  String _formatRupiah(num angka) => 
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  // Widget Pemisah Garis Putus-putus ala Struk Thermal
  Widget _buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.black87)),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekstraksi Konfigurasi Toko
    final bool enableOrderType = data['store']['enable_order_type'] == 1;
    final bool enableTableNumber = data['store']['enable_table_number'] == 1;
    final String? tableId = data['transaction']['table_id']?.toString();

    // Data Utama
    final trx = data['transaction'];
    final store = data['store'];
    final items = data['items'] as List<dynamic>;

    // Waktu Transaksi
    DateTime trxDate = DateTime.parse(trx['created_at']).toLocal();
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(trxDate);

    return Scaffold(
      backgroundColor: Colors.grey[200], // Background luar abu-abu
      appBar: AppBar(
        title: const Text('Detail Struk', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.primaryEmerald),
            onPressed: () {
              // TODO: Panggil fungsi Bluetooth Printer Thermal di sini
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menghubungkan ke printer...'))
              );
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 320, // Lebar simulasi kertas Thermal 80mm
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================== HEADER TOKO ==================
                Center(
                  child: Column(
                    children: [
                      const Text('SMART KASIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(store['name'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(store['address'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      Text(store['phone'] ?? '', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                _buildDashedLine(),

                // ================== INFO TRANSAKSI ==================
                Text(trx['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(formattedDate, style: const TextStyle(fontSize: 12)),
                Text('Kasir : ${trx['cashier_name']}', style: const TextStyle(fontSize: 12)),
                if (trx['shift_id'] != null)
                  Text('Shift : #${trx['shift_id']}', style: const TextStyle(fontSize: 12)),
                _buildDashedLine(),

                // ================== NO MEJA ==================
                if (enableTableNumber && tableId != null) ...[
                  Center(
                    child: Text('MEJA : ${tableId.padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _buildDashedLine(),
                ],

                // ================== DAFTAR ITEM ==================
                const Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                ...items.map((item) {
                  String namaItem = item['item_type'] == 'SERVICE' 
                      ? 'Jasa: ${item['product_name']}' 
                      : item['product_name'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaItem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        
                        // Dine In / Takeaway (Jika fitur ON)
                        if (enableOrderType && item['order_type'] != null)
                          Text(item['order_type'].toString().replaceAll('_', ' '), style: const TextStyle(fontSize: 10, color: Colors.black87)),
                        
                        // Qty, Harga & Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item['quantity']} × ${_formatRupiah(item['price'])}', style: const TextStyle(fontSize: 12)),
                            Text(_formatRupiah(item['subtotal']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        
                        // Catatan (Jika ada)
                        if (item['note'] != null && item['note'].toString().isNotEmpty)
                          Text('Catatan: ${item['note']}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                }).toList(),
                _buildDashedLine(),

                // ================== RINGKASAN HARGA ==================
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(fontSize: 12)), Text(_formatRupiah(trx['subtotal']), style: const TextStyle(fontSize: 12))]),
                if (trx['discount'] > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon', style: TextStyle(fontSize: 12)), Text('-${_formatRupiah(trx['discount'])}', style: const TextStyle(fontSize: 12))]),
                if (trx['tax'] > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pajak', style: TextStyle(fontSize: 12)), Text(_formatRupiah(trx['tax']), style: const TextStyle(fontSize: 12))]),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                    Text(_formatRupiah(trx['grand_total']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  ]
                ),
                _buildDashedLine(),

                // ================== PEMBAYARAN ==================
                const Center(child: Text('PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Text(trx['payment_method'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
                    Text(_formatRupiah(trx['payment_method'] == 'CASH' ? trx['paid_amount'] : trx['grand_total']), style: const TextStyle(fontSize: 12))
                  ]
                ),
                if (trx['payment_method'] == 'CASH')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      const Text('KEMBALI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
                      Text(_formatRupiah(trx['paid_amount'] - trx['grand_total']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                    ]
                  )
                else
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
                      Text('LUNAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                    ]
                  ),
                _buildDashedLine(),

                // ================== FOOTER ==================
                const SizedBox(height: 8),
                const Center(child: Text('TERIMA KASIH 🙏', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const Center(child: Text('SELAMAT DATANG KEMBALI', style: TextStyle(fontSize: 12))),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
