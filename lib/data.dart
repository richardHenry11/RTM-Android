import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:excel/excel.dart';

class Data extends StatefulWidget {
  const Data({super.key});

  @override
  State<Data> createState() => _DataState();
}

class _DataState extends State<Data> {
  final TextEditingController _siteId = TextEditingController();
  final TextEditingController _deviceId = TextEditingController();
  final TextEditingController _deviceName = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();

  List<Map<String, dynamic>> tableData = [];
  int pageSize = 15;
  int currentPage = 1;
  int totalPages = 1;
  String? _savedEmail = "memuat...";

  @override
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () async {
      await _loadEmail();
      await Future.delayed(Duration(milliseconds: 500)); // Memberi waktu tambahan
      _fetchDataTable();
    });
  }


  Future<void> _loadEmail() async {
  try {
    print("Memuat email dari SharedPreferences...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedEmail = prefs.getString('email') ?? "Tidak ada email tersimpan";
    });
    print("Email berhasil dimuat: $_savedEmail");
    _fetchDataTable();
  } catch (e) {
    print("Error saat memuat email: $e");
  }
}


  void _fetchDataTable() async {
    if (_savedEmail == null) {
      print("Email belum dimuat, tidak bisa fetch data");
      return;
    }

    print("Menghubungkan ke API dengan email: $_savedEmail...");
  
    try {
      final responseTable = await http.post(
        Uri.parse("https://rtm.envilife.co.id/api/data"),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'date_from': _startDate.text,
          'date_to': _endDate.text,
          'device_id': _deviceId.text,
          'device_name': _deviceName.text,
          'email': _savedEmail,
          'page': currentPage.toString(),
          'page_size': pageSize.toString(),
          'site_id': _siteId.text,
          'type': 'data'
        }),
      );

      print("Response status: ${responseTable.statusCode}");

      if (responseTable.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseTable.body);
        print("Data diterima: $data");

        setState(() {
          tableData = List<Map<String, dynamic>>.from(data["devices"].map((device) => {
            "Site ID": device["site_id"] ?? "N/A",
            "Device ID": device["device_id"] ?? "N/A",
            "Device Name": device["device_name"] ?? "N/A",
            "Sensor ID": device["sensor_id"] ?? "N/A",
            "Current1": device["current1"] ?? "N/A",
            "Power1": device["power1"] ?? "N/a",
            "Energy1": device["energy1"] ?? "N/A",
            "Frequency1": device['frequency1'] ?? "N/A",
            "PF1": device['pf1'] ?? "N/A",
            "MAC": device['MAC'] ?? "N/A",
            "BATT": device['Batt'] ?? "NULL",
            "RSSI": device['RSSI'] ?? "N/A",
            "Created At": device['created_at'] ?? "N/A",
            "Updated At": device['updated_at'] ?? "N/A",
            "Start Time": device["start_time"] ?? "N/A",
            "End Time": device["end_time"] ?? "N/A",
            "Running Time": device["running_time"] ?? "N/A",
            "Status": device["states"] ?? "Tidak ada status",
            "Volatage": device["voltage1"] ?? "NULL",
          }));
          totalPages = data['total_pages'] ?? 1;
        });
        print("Data berhasil diupdate ke UI.");
      } else {
        print("Gagal mengambil data: ${responseTable.statusCode}");
        print("Response body: ${responseTable.body}");
      }
    } catch (e) {
      print("Error saat fetch data: $e");
    }
  }


  void _changePage(int newPage) {
    if (newPage > 0 && newPage <= totalPages) {
      setState(() {
        currentPage = newPage;
      });
      _fetchDataTable();
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> exportToPDF(List<List<String>> data, BuildContext context) async {
    final pdf = pw.Document();

    // Debugging: Print data sebelum ekspor
    print("Data yang diekspor ke PDF: $data");

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.TableHelper.fromTextArray(
            headers: ["Site ID", "Device ID", "Device Name", "Start Time", "End Time", "Running Time", "Status"],
            data: data.isEmpty ? [["No Data", "No Data", "No Data", "No Data"]] : data,
            headerStyle: pw.TextStyle( 
              fontWeight: pw.FontWeight.bold
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.yellow300,
            )
          );
        },
      ),
    );

    // Menyimpan file di direktori aplikasi
    final directory = await getExternalStorageDirectory();
    final downloadDir = Directory('${directory!.path}/Download/data');

    // Pastikan folder Download ada
    if (!(await downloadDir.exists())) {
      await downloadDir.create(recursive: true);
      print("Folder Download berhasil dibuat di ${downloadDir.path}");
    }

    // Menyimpan file di direktori aplikasi
    final filePath = "${directory!.path}/Download/data/data_export.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    print("File PDF disimpan di: $filePath");

    // Notifikasi ke pengguna tanpa `navigatorKey`
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("File PDF berhasil diekspor ke folder Download!")),
    );

    // Opsi untuk menampilkan PDF setelah dibuat
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> exportToExcel(List<List<String>> data) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['sheet1'];


     // Add header
  sheet.appendRow(["Site ID", "Device ID", "Device Name", "Start Time", "End Time", "Running Time", "Status"].map((e) => TextCellValue(e)).toList());

    for (var row in data) {
      sheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }

  // save to local (temporary dir)
  var fileBytes = excel.save();
  if (fileBytes != null) {
    Directory? downloadsDir = await getExternalStorageDirectory(); // Mendapatkan direktori eksternal
    String downloadsPath = "${downloadsDir!.path}/Download/data"; // Folder Download

    // Pastikan folder Download ada
    Directory(downloadsPath).createSync(recursive: true);

    // Simpan file di folder Download
    String filePath = "$downloadsPath/data_export.xlsx";
    File(filePath).writeAsBytesSync(fileBytes);

    print("File disimpan di: $filePath");
  }
  }

  Widget _buildPagination() {
    List<Widget> pages = [];

    // Tombol Previous
    pages.add(
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 228, 108, 99)
        ),
        onPressed: currentPage > 1 ? () => _changePage(currentPage - 1) : null,
        child: const Text("Previous", style: TextStyle(color:Colors.white),),
      ),
    );

    // Halaman pertama
    pages.add(_buildPageButton(1));

    // Jika halaman lebih dari 5, tampilkan titik tiga jika perlu
    if (currentPage > 4) {
      pages.add(const Text("..."));
    }

    // Halaman sekitar halaman saat ini
    for (int i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i > 1 && i < totalPages) {
        pages.add(_buildPageButton(i));
      }
    }

    // Jika halaman terakhir belum ditampilkan
    if (currentPage < totalPages - 3) {
      pages.add(const Text("..."));
    }

    // Halaman terakhir
    if (totalPages > 1) {
      pages.add(_buildPageButton(totalPages));
    }

    // Tombol Next
    pages.add(
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green
        ),
        onPressed: currentPage < totalPages ? () => _changePage(currentPage + 1) : null,
        child: const Text("Next", style: TextStyle(color: Colors.white),),
      ),
    );

    return Wrap(
      spacing: 8.0,
      children: pages,
    );
  }

  Widget _buildPageButton(int page) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: currentPage == page ? Colors.blue : const Color.fromARGB(255, 246, 246, 246),
      ),
      onPressed: () => _changePage(page),
      child: Text("$page"),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Color(0xFF28ABEA),
      title: Text("Data", style: TextStyle(color: Colors.white)),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.1,
                      child: TextFormField(
                        controller: _siteId,
                        decoration: InputDecoration(
                          labelText: "Site ID",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.1,
                      child: TextFormField(
                        controller: _deviceId,
                        decoration: InputDecoration(
                          labelText: "Device ID",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.1,
                      child: TextFormField(
                        controller: _deviceName,
                        decoration: InputDecoration(
                          labelText: "Device name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDate,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Start Time",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, _startDate),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: TextFormField(
                      controller: _endDate,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "End Time",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, _endDate),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(
                          MediaQuery.of(context).size.height * 0.056,
                        ),
                        backgroundColor: Color(0xFF28ABEA),
                      ),
                      onPressed: _fetchDataTable,
                      child: Text("Filter", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(
                          MediaQuery.of(context).size.height * 0.056,
                        ),
                        backgroundColor: Color(0xFF28ABEA),
                      ),
                      onPressed: () async {
                        if (tableData.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Data kosong! Tidak bisa mengekspor.")),
                          );
                          return;
                        }
                        List<List<String>> excelData = tableData.map((row) => [
                          row["Site ID"].toString(),
                          row["Device ID"].toString(),
                          row["Device Name"].toString(),
                          row["Start Time"].toString(),
                          row["End Time"].toString(),
                          row["Running Time"].toString(),
                          row["Status"].toString(),
                        ]).toList();
                        await exportToPDF(excelData, context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("File PDF berhasil diekspor ke folder Download!")),
                        );
                      },
                      child: Text("PDF", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.fromHeight(
                          MediaQuery.of(context).size.height * 0.056,
                        ),
                        backgroundColor: Color(0xFF28ABEA),
                      ),
                      onPressed: () async {
                        if (tableData.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Data kosong! Tidak bisa mengekspor.")),
                          );
                          return;
                        }
                        List<List<String>> excelData = tableData.map((row) => [
                          row["Site ID"].toString(),
                          row["Device ID"].toString(),
                          row["Device Name"].toString(),
                          row["Start Time"].toString(),
                          row["End Time"].toString(),
                          row["Running Time"].toString(),
                          row["Status"].toString(),
                        ]).toList();
                        await exportToExcel(excelData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("File Excel berhasil diekspor ke folder Download!")),
                        );
                      },
                      child: Text("Excel", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Site ID")),
                      DataColumn(label: Text("Device ID")),
                      DataColumn(label: Text("Device Name")),
                      DataColumn(label: Text("Start Time")),
                      DataColumn(label: Text("End Time")),
                      DataColumn(label: Text("Running Time")),
                      DataColumn(label: Text("Status")),
                    ],
                    rows: tableData.map((data) {
                      return DataRow(
                        cells: [
                          DataCell(Text(data["Site ID"] ?? "N/A")),
                          DataCell(Text(data["Device ID"] ?? "N/A")),
                          DataCell(Text(data["Device Name"] ?? "N/A")),
                          DataCell(Text(data["Start Time"] ?? "N/A")),
                          DataCell(Text(data["End Time"] ?? "N/A")),
                          DataCell(Text(data["Running Time"] ?? "Tidak ada status")),
                          DataCell(Text(data["Status"] ?? "N/A")),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildPagination(),
            ],
          ),
        ),
      ),
    ),
  );
}
}
