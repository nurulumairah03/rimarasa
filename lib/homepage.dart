import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rimarasa/login.dart';
import 'package:rimarasa/generate_pantun.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String selectedMood = 'Semua';
  String username = '';
  bool isLoadingUsername = true;

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  Future<void> fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (snapshot.exists) {
        setState(() {
          username = snapshot['username'] ?? 'User';
          isLoadingUsername = false;
        });
      }
    } else {
      setState(() {
        isLoadingUsername = false;
      });
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343341),
      appBar: AppBar(
        backgroundColor: const Color(0xFF343341),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'RimaRasa',
          style: TextStyle(
            fontFamily: 'Playfair',
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(52, 51, 65, 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 80, // Adjust size as needed
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'RimaRasa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: 'Playfair',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Color.fromARGB(255, 0, 0, 0)),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 16,
                  fontFamily: 'Georgia',
                ),
              ),
              onTap: () => logoutUser(context),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          isLoadingUsername
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rima bertemu rasa\n     Selamat berkarya, $username!',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'Playfair',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                      style: const TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari pantun atau mood...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(0, 255, 241, 224),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          '✨ Pantun anda ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontFamily: 'Playfair',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection('pantuns')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            'Tiada mood tersedia.',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Georgia',
                              fontSize: 15,
                            ),
                          );
                        }

                        final allDocs = snapshot.data!.docs;
                        final Set<String> uniqueMoods = {
                          for (var doc in allDocs)
                            if (doc['emotion'] != null)
                              doc['emotion'] as String,
                        };

                        final moodTags = uniqueMoods.toList()..sort();

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              MoodButton(
                                text: 'Semua',
                                isSelected: selectedMood == 'Semua',
                                onTap:
                                    () =>
                                        setState(() => selectedMood = 'Semua'),
                              ),
                              MoodButton(
                                text: 'Kegemaran ♥️',
                                isSelected: selectedMood == 'Kegemaran',
                                onTap:
                                    () => setState(
                                      () => selectedMood = 'Kegemaran',
                                    ),
                              ),
                              ...moodTags.map(
                                (mood) => MoodButton(
                                  text: mood,
                                  isSelected: selectedMood == mood,
                                  onTap:
                                      () => setState(() => selectedMood = mood),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('pantuns')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Text(
                              'Tiada pantun dijumpai.\nAyuh cipta pantun baru!',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Georgia',
                                fontSize: 15,
                              ),
                            );
                          }

                          final docs =
                              snapshot.data!.docs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final pantunText =
                                    (data['pantun'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                final mood =
                                    (data['emotion'] ?? '')
                                        .toString()
                                        .toLowerCase();

                                final matchesMood =
                                    selectedMood == 'Semua' ||
                                    (selectedMood == 'Kegemaran' &&
                                        data['liked'] == true) ||
                                    mood == selectedMood.toLowerCase();

                                final matchesSearch =
                                    searchQuery.isEmpty ||
                                    pantunText.contains(searchQuery) ||
                                    mood.contains(searchQuery);

                                return matchesMood && matchesSearch;
                              }).toList();

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final pantun = doc['pantun'];
                              final docId = doc.id;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PantunDisplayPage(
                                            pantun: pantun,
                                            docId: docId,
                                          ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          212,
                                          250,
                                          238,
                                          223,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            255,
                                            159,
                                            137,
                                            111,
                                          ),
                                          width: 3.0,
                                        ),
                                      ),
                                      child: Text(
                                        pantun,
                                        style: const TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    if ((doc.data() as Map<String, dynamic>)
                                            .containsKey('liked') &&
                                        (doc.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['liked'] ==
                                            true)
                                      const Positioned(
                                        top: 20,
                                        right: 15,
                                        child: Text(
                                          '❤️',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeneratePantunPage()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 210, 187, 160),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Image.asset('assets/images/generate.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class MoodButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? const Color.fromARGB(141, 255, 255, 255)
                  : const Color.fromARGB(255, 253, 229, 201),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color.fromARGB(255, 196, 169, 138),
              width: 3.0,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF343341),
          ),
        ),
      ),
    );
  }
}
