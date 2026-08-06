import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram Layout',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const InstagramScreen(),
    );
  }
}

class InstagramScreen extends StatelessWidget {
  const InstagramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Top App Bar ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Instagram',
                    style: TextStyle(
                      fontFamily: 'Billabong',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 26),
                      const SizedBox(width: 18),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.send_outlined, size: 24),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: const Text(
                                '2',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),

            // ---------- Post Header ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.pink, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Corpuz',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_vert, size: 20),
                ],
              ),
            ),

            // ---------- Post Image (gradient placeholder) ----------
            Container(
              width: double.infinity,
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF9A825),
                    Color(0xFFE91E8C),
                    Color(0xFF6A5ACD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // ---------- Action Icons ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 26),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline, size: 24),
                  const SizedBox(width: 16),
                  Transform.rotate(
                    angle: -0.5,
                    child: const Icon(Icons.send_outlined, size: 22),
                  ),
                  const Spacer(),
                  const Icon(Icons.bookmark_border, size: 24),
                ],
              ),
            ),

            // ---------- Likes ----------
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '10547 Likes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),

            // ---------- Caption ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.black),
                  children: [
                    TextSpan(
                      text: '@Corpuz  ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: 'Lorem ipsum dolor sit amet, consectetur'),
                  ],
                ),
              ),
            ),

            // ---------- Hashtags ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '#lorem  #ipsum  #dolor  #sit  #amet  #consectetur',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),

            const Spacer(),
            const Divider(height: 1, thickness: 0.5),

            // ---------- Bottom Navigation Bar ----------
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Icon(Icons.home, size: 26),
                  Icon(Icons.search, size: 26),
                  Icon(Icons.add_box_outlined, size: 26),
                  Icon(Icons.smart_display_outlined, size: 26),
                  Icon(Icons.person_outline, size: 26),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}