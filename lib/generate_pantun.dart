import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:rimarasa/homepage.dart';
import 'package:rimarasa/pantun_edit_page.dart';
import 'package:rimarasa/pantun_info_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:dropdown_search/dropdown_search.dart';

const String geminiApiKey = 'YOUR_API_KEY';

class GeneratePantunPage extends StatefulWidget {
  const GeneratePantunPage({super.key});

  @override
  State<GeneratePantunPage> createState() => _GeneratePantunPageState();
}

class _GeneratePantunPageState extends State<GeneratePantunPage> {
  final List<String> emotions = [
    'Bangga',
    'Bersemangat',
    'Bingung',
    'Bosan',
    'Cemas',
    'Cemburu',
    'Gembira',
    'Kecewa',
    'Kesepian',
    'Letih',
    'Malas',
    'Marah',
    'Sayu',
    'Sedih',
    'Takut',
    'Tenang',
    'Terharu',
    'Tertekan',
    'Teruja',
    'Yakin',
  ];
  String? selectedEmotion;
  final TextEditingController descriptionController = TextEditingController();
  String generatedPantun = '';

  bool isLoading = false;

  Future<void> generatePantun() async {
    if (selectedEmotion == null || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila isi emosi dan cerita anda')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      generatedPantun = '';
    });

    const apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

    final prompt = '''
Anda ialah pakar penulisan pantun Melayu klasik.

Sila hasilkan SATU (1) pantun empat kerat yang memenuhi semua kriteria penulisan berikut:

1. Mengandungi **2 baris pembayang** (unsur alam/sekeliling) dan **2 baris maksud** (mesej sopan).
2. Gunakan **ayat yang pendek dan mudah difahami** (pemendekan ayat).
3. Gunakan **diksi yang indah dan sesuai dengan konteks emosi pengguna**.
4. Hadkan setiap baris kepada **8 hingga 12 suku kata sahaja**.
5. Pantun mesti mempunyai **rima akhir dalam susunan ABAB**.
   - Rima **pada hujung baris WAJIB**.
   - Rima **pada tengah dan awal baris DIGALAKKAN tetapi tidak wajib**.

Maklumat pengguna:
- Emosi: "$selectedEmotion"
- Cerita: "${descriptionController.text}"

Tulis **pantun sahaja tanpa sebarang penjelasan atau tajuk**.
''';

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('candidates') && data['candidates'].isNotEmpty) {
          final pantun = data['candidates'][0]['content']['parts'][0]['text'];

          // Save to Firestore and get docId
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final docRef = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('pantuns')
                .add({
                  'pantun': pantun,
                  'emotion': selectedEmotion,
                  'description': descriptionController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'liked': false, // default
                });

            final docId = docRef.id;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        PantunDisplayPage(pantun: pantun, docId: docId),
              ),
            );
          }
        } else {
          setState(() {
            generatedPantun = 'Tiada pantun dijumpai.';
          });
        }
      } else {
        setState(() {
          generatedPantun =
              'Ralat: ${response.statusCode} - ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        generatedPantun = 'Ralat: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343341),
      appBar: AppBar(
        backgroundColor: const Color(0xFF343341),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(' '), // Optional, keep if needed
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌸 Top Flower
            Center(
              child: Image.asset('assets/images/flower_top.png', height: 110),
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Cipta Pantun Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Apakah emosi anda sekarang?',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),

            DropdownSearch<String>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Cari emosi...",
                    hintStyle: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                itemBuilder:
                    (context, item, isSelected) => ListTile(
                      title: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 14,
                        ),
                      ),
                    ),
              ),
              items: emotions,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Sila pilih",
                  hintStyle: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              dropdownBuilder:
                  (context, selectedItem) => Text(
                    selectedItem ?? "Sila pilih",
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
              selectedItem: selectedEmotion,
              onChanged: (value) {
                setState(() => selectedEmotion = value);
              },
            ),

            const SizedBox(height: 20),
            const Text(
              'Bagaimana hari anda? Ceritakan sedikit apa yang anda lalui.',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: descriptionController,
                maxLines: 10,
                style: const TextStyle(
                  // 👈 user input style here
                  fontFamily: 'Georgia',
                  fontSize: 14,
                  color: Colors.black, // You can change if needed
                ),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Hari ini aku telah...',
                  hintStyle: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    color: Color.fromRGBO(117, 117, 117, 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : generatePantun,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 197, 171, 142),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Cipta ✨',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 30),

            // 🌸 Bottom Flower
            Center(
              child: Image.asset(
                'assets/images/flower_bottom.png',
                height: 120,
              ),
            ),

            if (generatedPantun.isNotEmpty) ...[
              const Text(
                'Pantun Dihasilkan:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.shade200),
                ),
                child: Text(generatedPantun),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PantunDisplayPage extends StatefulWidget {
  final String pantun;
  final String docId;

  const PantunDisplayPage({
    super.key,
    required this.pantun,
    required this.docId,
  });

  @override
  State<PantunDisplayPage> createState() => _PantunDisplayPageState();
}

class _PantunDisplayPageState extends State<PantunDisplayPage> {
  bool isLiked = false;

  void copyPantun() {
    Clipboard.setData(ClipboardData(text: widget.pantun));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pantun disalin ke papan klip!')),
    );
  }

  void sharePantun() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/pantun.png');
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([
        XFile(imagePath.path),
      ], text: 'Kongsi pantun anda! 🌸');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ralat semasa berkongsi: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLikedStatus();
  }

  void _loadLikedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('pantuns')
              .doc(widget.docId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          isLiked = data['liked'] == true; // default false if not found
        });
      }
    }
  }

  void toggleLike() async {
    setState(() => isLiked = !isLiked);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantuns')
          .doc(widget.docId)
          .update({'liked': isLiked});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isLiked ? 'Pantun disukai ❤️' : 'Tidak disukai 💔'),
      ),
    );
  }

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Pantun Anda 🌸',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 10),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    IconButton(
      onPressed: copyPantun,
      icon: const Icon(Icons.copy),
      tooltip: 'Salin',
    ),
    IconButton(
      onPressed: toggleLike,
      icon: Icon(
        Icons.favorite,
        color: isLiked ? Colors.pink : Colors.grey,
      ),
      tooltip: 'Suka',
    ),
    IconButton(
      onPressed: sharePantun,
      icon: const Icon(Icons.share),
      tooltip: 'Kongsi',
    ),
    IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantunInfoPage(docId: widget.docId),
      ),
    );
  },
  icon: const Icon(Icons.info_outline),
  tooltip: 'Maklumat',
),

    IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PantunEditPage(docId: widget.docId, initialPantun: widget.pantun),
          ),
        );
      },
      icon: const Icon(Icons.edit),
      tooltip: 'Edit',
    ),
    IconButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Padam Pantun'),
            content: const Text('Adakah anda pasti ingin memadam pantun ini?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Padam')),
            ],
          ),
        );

        if (confirm == true) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('pantuns')
                .doc(widget.docId)
                .delete();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pantun dipadam.')),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Homepage()),
              (Route<dynamic> route) => false,
            );
          }
        }
      },
      icon: const Icon(Icons.delete),
      tooltip: 'Padam',
    ),
  ],
),

              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Screenshot(
                    controller: screenshotController,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 500, // ⬅️ Increase height (adjust as needed)
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ), // ⬅️ More spacious
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: Colors.brown.shade200),
                          ),
                          child: Center(
                            child: Text(
                              widget.pantun,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16, // ⬅️ Bigger font
                                fontFamily: 'Georgia',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 0,
                          right: 0,
                          child: Image.asset(
                            'assets/images/bunga_top.png',
                            height: 200,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Image.asset(
                            'assets/images/bunga_bottom.png',
                            height: 200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Homepage()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8986C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Kembali ke Laman Utama',
                      style: TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'Georgia', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
