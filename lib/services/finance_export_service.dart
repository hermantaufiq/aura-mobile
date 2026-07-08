import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/finance_model.dart';

class FinanceExportService {
  static Future<void> exportToPdf(List<FinanceModel> finances, String userName) async {
    final pdf = pw.Document();

    // Sort finances by date descending
    finances.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var item in finances) {
      if (item.isIncome) {
        totalIncome += item.amount;
      } else {
        totalExpense += item.amount;
      }
    }
    double balance = totalIncome - totalExpense;

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan Keuangan', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('AURA AI Mobile App', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Pengguna: $userName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Dicetak: ${dateFormatter.format(DateTime.now())}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Pemasukan', currencyFormatter.format(totalIncome), PdfColors.green700),
                  _buildSummaryItem('Total Pengeluaran', currencyFormatter.format(totalExpense), PdfColors.red700),
                  _buildSummaryItem('Saldo Akhir', currencyFormatter.format(balance), PdfColors.blue700),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Transactions Table
            pw.Text('Rincian Transaksi', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Kategori', 'Tipe', 'Catatan', 'Jumlah'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
              },
              data: finances.map((f) {
                return [
                  dateFormatter.format(f.date),
                  f.category,
                  f.isIncome ? 'Pemasukan' : 'Pengeluaran',
                  f.note.isEmpty ? '-' : f.note,
                  currencyFormatter.format(f.amount),
                ];
              }).toList(),
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    // Save and open the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Laporan_Keuangan_AURA.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open file using open_file package
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildSummaryItem(String title, String amount, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(amount, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
