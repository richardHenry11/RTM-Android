  import 'dart:convert';

  import 'package:flutter/material.dart';
  import "package:http/http.dart" as http;
  import 'package:shared_preferences/shared_preferences.dart';
  import 'dart:async';

  class Register extends StatefulWidget {
    const Register({super.key});

    @override
    State<Register> createState() => _RegisterState();
  }

  class _RegisterState extends State<Register> {
    final _formKeyReg = GlobalKey<FormState>();
    String? _email = "";
    final TextEditingController _siteId = TextEditingController();
    final List<String> itemsId = [];
    final TextEditingController _deviceId = TextEditingController();
    final TextEditingController _deviceName = TextEditingController();
    final List<String> itemsRole = ["active", "inactive"];
    String? selectedValue;
    String? selectedStatus;

    @override
    void initState() {
      super.initState();
      _emaiLoaded();
    }

    Future<void> _emaiLoaded() async {
      final emailPref = await SharedPreferences.getInstance();
      setState(() {
        _email = emailPref.getString('email') ?? 'admin@rtm.envilife.id';
      });
      await _emailReaderToAPI();
    }

    Future<void> _emailReaderToAPI() async {
      if(_email == null){
        print("email belum dimuat");
        return;
      }

      print("Register page Connecting to API...");

      final reply = await http.post(
        Uri.parse("https://rtm.envilife.co.id/api/data"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': '$_email', 'type':'site_id'})
      );

      print("JSON parsed: ${reply.statusCode}");

      if (reply.statusCode == 200) {
        final data = jsonDecode(reply.body);
        print("✅ Data diterima: $data");

        if (data['site_id'] != null) {
          setState(() {
            itemsId.clear();
            itemsId.addAll(List<String>.from(data['site_id']));
          });
          print("📌 Updated dropdown items: $itemsId"); // Debug log
        } else {
          print("❌ Failed to fetch data. Reply: ${reply.body}");
        }
      }
    }

    void _generate() async {
    if (_email == null) {
      print("⚠️ Email belum dimuat, coba lagi...");
      return; // Menghentikan eksekusi jika email belum siap
    }

    print(" Mengirim permintaan ke API untuk generate device_id...");

    final replyGen = await http.post(
      Uri.parse("https://rtmonitor.mdtapps.id/api/data"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': 'generate_device_id',
        'email': _email,
        'site_id': _siteId.text,
      }),
    );

    print("Response API: ${replyGen.statusCode}");

    if (replyGen.statusCode == 200) {
      final data = jsonDecode(replyGen.body);
      print("✅ Data diterima: $data");

      if (data['device_id'] != null) {
        setState(() {
          _deviceId.text = data['device_id'];
        });
        print("📌 Updated dropdown items: $_deviceId"); // Debug log
      } else {
        print("❌ Data tidak valid. Response: ${replyGen.body}");
      }
    } else {
      print("❌ Gagal mendapatkan data. Status code: ${replyGen.statusCode}");
    }
  }

  void register() async {
    if(_email == null){
      print("email hasnt been loaded");
      return;
    }

    print(" Mengirim permintaan ke API untuk registrasi device...");

    final responseReg = await http.post(
      Uri.parse("https://rtmonitor.mdtapps.id/api/data"),
      headers: {'content-type':'application/json'},
      body: jsonEncode(
        {
              'device_id': _deviceId.text,
              'device_name': _deviceName.text,
              'email': _email,
              'site_id': _siteId.text,
              'status': selectedValue,
              'type': "register_device"
        }
      ),
    );

    print("Response API: ${responseReg.statusCode}");
    if (responseReg.statusCode == 200) {
      print("registration succesful");
      _showSuccessDialog();
    } else {
      print("registration failed.. Status : ${responseReg.statusCode}");
      _showErrorDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("registration successful"),
          content: Text("Device has successfully added"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Registration Failed"),
          content: Text("Error have occured. Please Try Again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showDialogValidation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            "Form Invalid!",
            style: TextStyle(color: Colors.red),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // ❗ Penting agar tidak memenuhi layar
          children: [
            Icon(
              Icons.close,
              size: 50.0,
              color: Colors.red,
            ),
            SizedBox(height: 10),
            Center(child: Text("Please fill the form's credentials correctly 😊.")),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF28ABEA),
          title: Text("Register Device", style: TextStyle(color: Colors.white),)
        ),
        body: 
        Padding(
          padding: const EdgeInsets.all(8.0),
          child:
          Form(
            key: _formKeyReg,
            child:
              Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(
                      MediaQuery.of(context).size.width * 0.90,
                      40
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    backgroundColor: Color.fromARGB(255, 182, 182, 182),
                  ),
                  onPressed: (){
                    // func
                    
                print("itemsId: $itemsId");
                  },
                  child: Text("Get Site Id", style: TextStyle(color: Colors.white),)
                ),
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.52,
                      child: TextFormField(
                        enabled: false,
                        controller: _siteId,
                        validator: (value) {
                          if (value == null || value.isEmpty){
                            return 'choose site ID';
                          }
                        },
                        decoration: InputDecoration(
                          labelText: "Site ID",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10))
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        selectedValue = value;
                        _siteId.text = value;  // make sure this updated Correctly
                      });
                      print("📌 Site ID selected: $_siteId.text");
                    },
                    itemBuilder: (context) {
                      if (itemsId.isEmpty) {
                        return [PopupMenuItem<String>(value: "", child: Text("No Data"))];
                      }
                      return itemsId.map((String value) {
                        return PopupMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        color: Colors.blue,
                      ),
                      height: 47,
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.arrow_drop_down_circle, size: 30, color: Colors.white),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        backgroundColor: Colors.green,
                        minimumSize: Size(10, 45)
                      ),
                      onPressed: (){
                        // funct Button Here!
                        _generate();
                      },
                      child: Text("Generate", style: TextStyle(color: Colors.white),)
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 1,
                    child: TextFormField(
                      enabled: false,
                      controller: _deviceId,
                      decoration: InputDecoration(
                        labelText: "Device ID",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child:
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.90,
                    child: 
                      TextFormField(
                        enabled: true,
                        controller: _deviceName,
                        validator: (value) {
                          if (value == null || value.isEmpty){
                            return 'Please fill Device name ';
                          }
                        },
                        decoration: 
                        InputDecoration(
                          labelText: "Device Name",
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)
                        ), 
                        )
                      )
                  )
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Choose one of the options!';
                          }
                        return null;
                      },
                    hint: Text("Select State"),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white, // Warna latar belakang
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25), // Mengubah border menjadi lonjong
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    items: itemsRole.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedValue = newValue;
                        print(selectedValue);
                      });
                    },
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.green,
                    minimumSize: Size(MediaQuery.of(context).size.width * 0.9, MediaQuery.of(context).size.height * 0.08)
                  ),
                  onPressed: (){
                    // func here!
                    if (_formKeyReg.currentState!.validate()){
                        register();
                      } else {
                        _showDialogValidation();
                      }
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),)
              )
            ],
          ),
          )
        )
      );
    }
  }