import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';

class PantunEditPage extends StatefulWidget {
  final String docId;
  final String initialPantun;

  const PantunEditPage({
    super.key,
    required this.docId,
    required this.initialPantun,
  });

  @override
  State<PantunEditPage> createState() => _PantunEditPageState();
}

class _PantunEditPageState extends State<PantunEditPage> {
  late TextEditingController pantunController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    pantunController = TextEditingController(text: widget.initialPantun);
  }

  Future<void> savePantun() async {
    final newPantun = pantunController.text.trim();

    if (newPantun.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pantun tidak boleh kosong')),
      );
      return;
    }

    setState(() => isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pantuns')
          .doc(widget.docId)
          .update({'pantun': newPantun});
    }

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pantun berjaya dikemas kini!')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Homepage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    pantunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7E4),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color.fromARGB(255, 0, 0, 0),
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Pantun',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 58, 51, 41),
          ),
        ),
        elevation: 2,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 400,
                alignment: Alignment.center,
                child: TextField(
                  controller: pantunController,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontFamily: 'Georgia'),
                  decoration: InputDecoration(
                    hintText: 'Masukkan pantun yang dikemas kini',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: isSaving ? null : savePantun,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8986C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
