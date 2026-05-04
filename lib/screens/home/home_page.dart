import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import '../../core/services/api_service.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';

import '../cart/cart_page.dart';
import '../order/history_page.dart';
import '../ai/recommendation_page.dart';
import '../maps/maps_page.dart';
import '../games/mini_game_page.dart';
import '../profile/profile_page.dart';
import '../converter/converter_page.dart';
import '../../widgets/add_product_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final api = ApiService();

  List<Product> products = [];
  List<Product> filteredProducts = [];

  bool isLoading = true;

  String role = "user";
  int currentIndex = 0;

  String selectedCategory = "All";
  String searchQuery = "";

  final Color primaryColor = const Color(0xFF3E2723); // DARK COFFEE
  final Color accentColor = const Color(0xFFD7CCC8); // DARK BG

  final List<String> categories = [
    "All",
    "Espresso",
    "Latte",
    "Cappuccino",
    "Americano",
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
    getRole();
  }

  Future<void> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString("role") ?? "user";
    });
  }

  Future<void> fetchProducts() async {
    final data = await api.getProducts();

    setState(() {
      products = data;
      filteredProducts = data;
      isLoading = false;
    });
  }

  void filterProducts() {
    setState(() {
      filteredProducts = products.where((p) {
        final matchSearch = p.name.toLowerCase().contains(
          searchQuery.toLowerCase(),
        );

        final matchCategory =
            selectedCategory == "All" ||
            p.name.toLowerCase().contains(selectedCategory.toLowerCase());

        return matchSearch && matchCategory;
      }).toList();
    });
  }

  // ======================
  // 🔥 PREMIUM HOME UI
  // ======================
  Widget buildHome() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: fetchProducts,
      child: Column(
        children: [
          // 🔥 PREMIUM BANNER
          Container(
            margin: const EdgeInsets.all(12),
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black54,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecommendationPage()),
                );
              },
              child: Row(
                children: [
                  // LOTTIE
                  SizedBox(
                    width: 120,
                    child: Lottie.asset('assets/lottie/coffee2.json'),
                  ),

                  const SizedBox(width: 10),

                  // TEXT
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Coffee Recommender",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Temukan kopi favoritmu sekarang ☕",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cari kopi...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                searchQuery = value;
                filterProducts();
              },
            ),
          ),

          const SizedBox(height: 10),

          // 🧋 CATEGORY
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;

                return GestureDetector(
                  onTap: () {
                    selectedCategory = cat;
                    filterProducts();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 🛍 GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return ProductCard(product: filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> pages() {
    return [
      buildHome(),
      const MiniGamePage(),
      const RecommendationPage(),
      const MapsPage(),
      const ProfilePage(),
      const ConverterPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("KOPISKUY", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
          if (role == "admin")
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductPage()),
                );
                fetchProducts();
              },
            ),
        ],
      ),
      body: pages()[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: "Game",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "AI"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Maps"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: "Converter",
          ),
        ],
      ),
    );
  }
}
