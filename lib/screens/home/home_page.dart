import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../core/services/api_service.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';

import '../cart/cart_page.dart';
import '../order/history_page.dart';
import '../chatbot/chatbot_page.dart';
import '../games/mini_game_page.dart';
import '../profile/profile_page.dart';
import '../converter/converter_page.dart';
import '../../widgets/add_product_page.dart';
import '../../core/services/currency_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final api = ApiService();

  StreamSubscription<ServiceStatus>? serviceStatusStream;

  bool isGpsDialogOpen = false;

  List<Product> products = [];
  List<Product> filteredProducts = [];

  bool isLoading = true;
  Map<String, dynamic>? recommendedCoffee;

  String role = "user";
  int currentIndex = 0;

  String selectedCategory = "All";
  String searchQuery = "";

  final Color primaryColor = const Color(0xFF3E2723);
  final Color accentColor = const Color(0xFFF5F1EE);

  int currentBanner = 0;

  // =========================
  // 🌍 TIME + GPS
  // =========================
  Timer? timer;

  DateTime currentTime = DateTime.now();

  String selectedTimezone = "WIB";

  final Map<String, String> timezoneMap = {
    "WIB": "Asia/Jakarta",
    "WITA": "Asia/Makassar",
    "WIT": "Asia/Jayapura",
    "London": "Europe/London",
  };

  final Map<String, int> timezoneOffset = {
    "WIB": 7,
    "WITA": 8,
    "WIT": 9,
    "London": 1,
  };

  final List<String> banners = [
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
    'assets/images/banner4.jpg',
    'assets/images/banner5.jpg',
  ];

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
    initializeTime();
    listenGpsStatus();
    loadRecommendation();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          currentTime = currentTime.add(
            const Duration(seconds: 1),
          );
        });
      },
    );
  }

  // =========================
  // 🌍 INIT GPS TIME
  // =========================
  Future<void> initializeTime() async {
    await detectTimezoneFromGPS();
    await fetchTime();
  }

  void listenGpsStatus() {
    serviceStatusStream = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) async {
        // GPS DIMATIKAN
        if (status == ServiceStatus.disabled) {
          if (isGpsDialogOpen) return;

          isGpsDialogOpen = true;

          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text("GPS Dimatikan"),
                  ],
                ),
                content: const Text(
                  "GPS harus aktif agar aplikasi dapat menyesuaikan zona waktu secara otomatis.",
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      await Geolocator.openLocationSettings();

                      isGpsDialogOpen = false;
                    },
                    child: const Text(
                      "Aktifkan GPS",
                    ),
                  ),
                ],
              );
            },
          );
        }

        // GPS AKTIF KEMBALI
        else if (status == ServiceStatus.enabled) {
          isGpsDialogOpen = false;

          await detectTimezoneFromGPS();
          await fetchTime();
        }
      },
    );
  }

  // =========================
  // 📍 DETECT TIMEZONE FROM GPS
  // =========================
  Future<void> detectTimezoneFromGPS() async {
    try {
      // =========================
      // CEK GPS AKTIF
      // =========================
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Jika GPS belum aktif
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double longitude = position.longitude;
      if (longitude >= 95 && longitude < 115) {
        selectedTimezone = "WIB";
      } else if (longitude >= 115 && longitude < 130) {
        selectedTimezone = "WITA";
      } else if (longitude >= 130) {
        selectedTimezone = "WIT";
      } else {
        selectedTimezone = "London";
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  // =========================
  // 🌍 FETCH TIME FROM API
  // =========================
  Future<void> fetchTime() async {
    try {
      final timezone = timezoneMap[selectedTimezone]!;

      final response = await http.get(
        Uri.parse(
          "https://worldtimeapi.org/api/timezone/$timezone",
        ),
      );

      final data = jsonDecode(response.body);

      final datetime = DateTime.parse(
        data["datetime"],
      );

      if (!mounted) return;

      setState(() {
        currentTime = datetime;
      });
    } catch (e) {
      debugPrint(
        "Error fetch time: $e",
      );
    }
  }

  void convertTimezone(String newZone) {
    final currentOffset = timezoneOffset[selectedTimezone]!;

    final newOffset = timezoneOffset[newZone]!;

    final difference = newOffset - currentOffset;

    setState(() {
      currentTime = currentTime.add(
        Duration(hours: difference),
      );

      selectedTimezone = newZone;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    serviceStatusStream?.cancel();
    super.dispose();
  }

  Future<void> getRole() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      role = prefs.getString("role") ?? "user";
    });
  }

  Future<void> fetchProducts() async {
    final data = await api.getProducts();

    if (!mounted) return;

    setState(() {
      products = data;
      filteredProducts = data;
      isLoading = false;
    });
  }

  Future<void> loadRecommendation() async {
    try {
      final data = await api.getRecommendation();

      if (data.isNotEmpty) {
        setState(() {
          recommendedCoffee = data.first;
        });
      }
    } catch (e) {
      debugPrint("Recommendation Error: $e");
    }
  }

  void filterProducts() {
    setState(() {
      filteredProducts = products.where((p) {
        final matchSearch = p.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );

        final matchCategory = selectedCategory == "All" ||
            p.name.toLowerCase().contains(
                  selectedCategory.toLowerCase(),
                );

        return matchSearch && matchCategory;
      }).toList();
    });
  }

  Widget buildHome() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: fetchProducts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            CarouselSlider(
              items: banners.map((image) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      25,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                height: 180,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.90,
                autoPlayInterval: const Duration(
                  seconds: 3,
                ),
                onPageChanged: (index, reason) {
                  setState(() {
                    currentBanner = index;
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map(
                (entry) {
                  return AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    width: currentBanner == entry.key ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      color: currentBanner == entry.key
                          ? primaryColor
                          : Colors.grey.shade400,
                    ),
                  );
                },
              ).toList(),
            ),

            const SizedBox(height: 20),
            // =========================
// ☕ AI RECOMMENDATION CARD
// =========================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4E342E),
                    Color(0xFF3E2723),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // =========================
                  // ICON
                  // =========================
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.local_cafe,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // =========================
                  // TEXT CONTENT
                  // =========================
                  Expanded(
                    child: recommendedCoffee == null
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Belum ada rekomendasi",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: const Text(
                                      "AI Recommendation",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                recommendedCoffee!["name"],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyService.instance.format(
                                  recommendedCoffee!["price"],
                                ),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Sering kamu pesan ☕",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(width: 10),

                  // =========================
                  // BUTTON
                  // =========================
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      if (recommendedCoffee == null) return;

                      await api.addToCart(
                        recommendedCoffee!["id"],
                        1,
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "${recommendedCoffee!["name"]} ditambahkan ke cart ☕",
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            color: primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Pesan",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // 🔍 SEARCH
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Cari kopi favoritmu...",
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  searchQuery = value;
                  filterProducts();
                },
              ),
            ),

            const SizedBox(height: 18),

            // =========================
            // 🧋 CATEGORY
            // =========================
            SizedBox(
              height: 42,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];

                  final isSelected = cat == selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                      });

                      filterProducts();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 250,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.05,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Text(
                "Menu Favorit",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // 🛍 PRODUCT GRID
            // =========================
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,

                // 🔥 FIX OVERFLOW
                childAspectRatio: 0.58,

                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                return ProductCard(
                  product: filteredProducts[index],
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<Widget> pages() {
    return [
      buildHome(),
      const MiniGamePage(),
      const ChatbotPage(),
      const ProfilePage(),
      const ConverterPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat(
      'HH:mm:ss',
    ).format(currentTime);

    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: accentColor,
        automaticallyImplyLeading: false,
        centerTitle: true,

        // =========================
        // ⏰ CLOCK CENTER
        // =========================
        title: GestureDetector(
          onTap: () async {
            final value = await showMenu<String>(
              context: context,
              position: const RelativeRect.fromLTRB(
                100,
                80,
                100,
                0,
              ),
              items: timezoneMap.keys.map(
                (zone) {
                  return PopupMenuItem<String>(
                    value: zone,
                    child: Text(zone),
                  );
                },
              ).toList(),
            );

            if (value == null) return;

            convertTimezone(value);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                selectedTimezone,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        leadingWidth: 130,

        leading: Padding(
          padding: const EdgeInsets.only(
            left: 14,
          ),
          child: Center(
            child: Text(
              "Kopiskuy.",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CartPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryPage(),
                ),
              );
            },
          ),
          if (role == "admin")
            IconButton(
              icon: Icon(
                Icons.add,
                color: primaryColor,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddProductPage(),
                  ),
                );

                fetchProducts();
              },
            ),
        ],
      ),
      body: pages()[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: "Game",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: "Converter",
          ),
        ],
      ),
    );
  }
}
