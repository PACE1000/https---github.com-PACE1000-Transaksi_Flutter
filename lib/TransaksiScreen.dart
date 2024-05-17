import 'package:cobatransaksi/TransaksiController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransaksiScreen extends StatefulWidget {
  TransaksiScreen({Key? key}) : super(key: key);

  @override
  _TransaksiScreenState createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  late Future<List<Map<String, dynamic>>> product;
  List<Map<String, dynamic>> selectedItems = [];
  List<TextEditingController> controllers = [];
  TransaksiController _transaksiController = TransaksiController();

  @override
  void initState() {
    super.initState();
    product = _transaksiController.ambil_data();
  }

  @override
  void dispose() {
    // Dispose all TextEditingController instances
    controllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  int getTotalBarang() {
    int total = 0;
    for (var controller in controllers) {
      int jumlah = int.tryParse(controller.text) ?? 0;
      total += jumlah;
    }
    return total;
  }

  String getTotalHarga() {
    int total = 0;
    for (var i = 0; i < selectedItems.length; i++) {
      var item = selectedItems[i];
      var jumlah = int.tryParse(controllers[i].text) ?? 0; // Retrieve quantity from corresponding controller
      var harga = int.tryParse(item['Harga']) ?? 0;
      total += harga * jumlah;
    }
    return total.toString();
  }

  void kirim() {
    for (var i = 0; i < selectedItems.length; i++) {
      var item = selectedItems[i];
      var Jumlah = int.parse(controllers[i].text);
      _transaksiController.kurang_stok(item['Nama'], Jumlah);
    }
  }

  void _addItem(Map<String, dynamic> item) {
    setState(() {
      selectedItems.add(item);
      controllers.add(TextEditingController(text: item['Jumlah']));
    });
  }

  void _removeItem(int index) {
    setState(() {
      selectedItems.removeAt(index);
      controllers[index].dispose();
      controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
      ),
      body: Column(
        children: <Widget>[
          TypeAheadField<Map<String, dynamic>>(
            suggestionsCallback: (pattern) async {
              return await _getSuggestions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion['Nama']),
                subtitle: Text('Harga: ${suggestion['Harga']}, Jumlah: ${suggestion['Jumlah']}'),
              );
            },
            onSelected: (suggestion) {
              _addItem(suggestion);
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final item = selectedItems[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama: ${item['Nama']}'),
                      Text('Harga: ${item['Harga']}'),
                      TextField(
                        controller: controllers[index],
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            controllers[index].text = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _removeItem(index);
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Harga'),
                    Text('Total Barang'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(getTotalHarga()), // Display total harga
                    Text(getTotalBarang().toString()), // Display total barang
                  ],
                ),
                TextButton(
                  onPressed: () {
                    kirim();
                    printing();
                  },
                  child: const Text('Bayar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getSuggestions(String query) async {
    List<Map<String, dynamic>> data = await product;
    List<Map<String, dynamic>> matches = [];
    for (var item in data) {
      if (item['Nama'].toLowerCase().contains(query.toLowerCase())) {
        matches.add(item);
      }
    }
    return matches;
  }

  void printing() {
    for (var item in selectedItems) {
      // Call your printing logic here
      print('Produk: ${item['Nama']}, Jumlah: ${item['Jumlah']}, Total Harga: ${getTotalHarga()}');
    }
  }
}

class TransaksiController {
  Future<List<Map<String, dynamic>>> ambil_data() async {
    List<Map<String, dynamic>> item = [];
    try {
      String uri = "http://10.31.17.207/cobaan/ambil_data.php";
      var res = await http.get(Uri.parse(uri));
      if (res.body.isNotEmpty) {
        item = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        print(item);
      } else {
        print("kosong");
      }
      return item;
    } catch (e) {
      print(e);
      return item;
    }
  }

  Future<void> kurang_stok(String Nama, int stok) async {
    if (Nama.isNotEmpty || stok.toString().isNotEmpty) {
      try {
        String uri = 'http://10.31.17.207/cobaan/kurang_stok.php';
        var res = await http.post(Uri.parse(uri), body: {
          "Nama": Nama,
          "Jumlah": stok.toString(),
        });

        if (res.body.isNotEmpty) {
          var response = json.decode(res.body);
          if (response["success"] == "true") {
            print("Berhasil Terkirim");
          } else {
            print("Gagal Terkirim");
            print("Error: ${response["message"]}");
          }
        } else {
          print("Empty response from server");
        }
      } catch (e) {
        print(e);
      }
    }
  }
}
