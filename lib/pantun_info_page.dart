import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PantunInfoPage extends StatefulWidget {
  final String docId;

  const PantunInfoPage({super.key, required this.docId});

  @override
  State<PantunInfoPage> createState() => _PantunInfoPageState();
}

class _PantunInfoPageState extends State<PantunInfoPage> {
  String? emotion;
  String? description;
  String? pantunText;
  String? aiDescription;
  DateTime? createdAt;
  bool isLoading = true;

  final String apiKey = 'YOUR_API_KEY';

  @override
  void initState() {
    super.initState();
    _loadPantunAndGenerateAI();
  }

  Future<void> _loadPantunAndGenerateAI() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('pantuns')
              .doc(widget.docId)
              .get();

      final data = doc.data();
      if (data == null) return;

      emotion = data['emotion'];
      description = data['description'];
      pantunText = data['pantun'];
      final timestamp = data['timestamp'];
      createdAt = timestamp != null ? (timestamp as Timestamp).toDate() : null;

      if (pantunText != null) {
        aiDescription = await _generateAIDescription(pantunText!);
      }
    } catch (e) {
      aiDescription = 'Gagal menjana huraian AI: $e';
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String> _generateAIDescription(String pantun) async {
    const apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';

    final prompt = '''
Anda ialah pakar sastera Melayu klasik.

Berdasarkan pantun berikut, sila berikan satu huraian pendek (2-3 ayat) dalam Bahasa Melayu mengenai makna tersirat, mesej yang ingin disampaikan, dan emosi yang mungkin dirasai oleh pembaca.

Pantun:
"$pantun"

Tulis huraian sahaja tanpa tajuk atau sebarang tambahan lain.
''';

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
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
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'Tiada huraian dijana.';
        }
        return 'Tiada maklum balas dari model.';
      } else {
        return 'Ralat API: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Ralat sambungan: $e';
    }
  }

  String _getFormattedDate(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final month = DateFormat('MMMM').format(date);
    final year = date.year;
    final time = DateFormat('h.mm a')
        .format(date)
        .toLowerCase()
        .replaceAll('am', 'a.m')
        .replaceAll('pm', 'p.m');
    return '$day$suffix $month $year, $time';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildDisplayBox(String content, {double minHeight = 50}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        content,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Georgia',
          height: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7E4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Penerangan tentang Pantun ✨',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (createdAt != null) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _getFormattedDate(createdAt!),
                            style: _valueStyle,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Text(
                        'Mood',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildDisplayBox(emotion ?? '-'),

                      const SizedBox(height: 20),
                      const Text(
                        'Senario pantun',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildDisplayBox(description ?? '-'),

                      const SizedBox(height: 20),
                      const Text(
                        'Maksud di sebalik pantun',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildDisplayBox(aiDescription ?? '-', minHeight: 120),
                    ],
                  ),
                ),
              ),
    );
  }
}

const TextStyle _valueStyle = TextStyle(fontSize: 15, fontFamily: 'Georgia');
