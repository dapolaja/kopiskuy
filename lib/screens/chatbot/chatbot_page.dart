import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFF5F1EE);

  bool isLoading = false;

  List<Map<String, dynamic>> messages = [];

  String chatKey = "";

  @override
  void initState() {
    super.initState();
    initChat();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // =========================
  // INIT CHAT USER
  // =========================
  Future<void> initChat() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt("user_id") ?? 0;

    // chat khusus tiap user
    chatKey = "chat_messages_$userId";

    await loadMessages();
  }

  // =========================
  // LOAD CHAT
  // =========================
  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(chatKey);

    if (data != null) {
      final decoded = jsonDecode(data);

      setState(() {
        messages = List<Map<String, dynamic>>.from(decoded);
      });
    } else {
      setState(() {
        messages = [
          {
            "role": "bot",
            "message":
                "Halo ☕ Saya AI Barista Kopiskuy.\nTanyakan rekomendasi kopi, promo, atau menu favoritmu."
          }
        ];
      });

      await saveMessages();
    }

    scrollToBottom();
  }

  // =========================
  // SAVE CHAT
  // =========================
  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(messages);

    await prefs.setString(
      chatKey,
      encoded,
    );
  }

  // =========================
  // CLEAR CHAT
  // =========================
  Future<void> clearChat() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(chatKey);

    setState(() {
      messages = [
        {
          "role": "bot",
          "message":
              "Halo ☕ Saya AI Barista Kopiskuy.\nTanyakan rekomendasi kopi, promo, atau menu favoritmu."
        }
      ];
    });

    await saveMessages();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        content: const Text(
          "Riwayat chat berhasil dihapus",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // =========================
  // SEND MESSAGE TO AI
  // =========================
  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "message": text,
      });

      isLoading = true;
    });

    await saveMessages();

    messageController.clear();

    scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(
          "https://openrouter.ai/api/v1/chat/completions",
        ),
        headers: {
          "Authorization":
              "API_KEY",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content":
                  "Kamu adalah AI Barista Kopiskuy. Jawab singkat, ramah, dan fokus tentang kopi."
            },
            {
              "role": "user",
              "content": text,
            }
          ]
        }),
      );

      final data = jsonDecode(response.body);

      final reply = data["choices"][0]["message"]["content"];

      setState(() {
        messages.add({
          "role": "bot",
          "message": reply,
        });

        isLoading = false;
      });

      await saveMessages();

      scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add({
          "role": "bot",
          "message": "Maaf AI sedang bermasalah ☕",
        });

        isLoading = false;
      });

      await saveMessages();
    }
  }

  // =========================
  // AUTO SCROLL
  // =========================
  void scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  // =========================
  // MESSAGE BUBBLE
  // =========================
  Widget buildMessageBubble(
    Map<String, dynamic> msg,
  ) {
    final isUser = msg["role"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.coffee_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              constraints: const BoxConstraints(
                maxWidth: 300,
              ),
              decoration: BoxDecoration(
                color: isUser ? primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(
                    isUser ? 24 : 6,
                  ),
                  bottomRight: Radius.circular(
                    isUser ? 6 : 24,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.05,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                msg["message"],
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                  height: 1.6,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
          if (isUser)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.person,
                color: primaryColor,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: accentColor,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: primaryColor,
        ),
        title: Column(
          children: [
            Text(
              "AI Barista",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              "Online",
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                    ),
                    title: const Text(
                      "Hapus Chat",
                    ),
                    content: const Text(
                      "Yakin ingin menghapus semua riwayat chat?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            false,
                          );
                        },
                        child: const Text(
                          "Batal",
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                clearChat();
              }
            },
            icon: Icon(
              Icons.delete_outline_rounded,
              color: primaryColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessageBubble(
                  messages[index],
                );
              },
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "AI sedang mengetik...",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              22,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    0.04,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Tanya rekomendasi kopi...",
                        hintStyle: TextStyle(
                          color: Colors.brown.shade300,
                        ),
                        prefixIcon: Icon(
                          Icons.chat_bubble_outline,
                          color: primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(
                            0.85,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(
                            0.25,
                          ),
                          blurRadius: 12,
                          offset: const Offset(
                            0,
                            6,
                          ),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
