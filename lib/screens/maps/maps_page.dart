import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  LatLng? userLocation;
  final MapController mapController = MapController();

  final Color primaryColor = const Color(0xFF6F4E37);
  final Color accentColor = const Color(0xFFD7CCC8);

  final List<Map<String, dynamic>> coffeeShops = [
    {"name": "Kopiskuy Depok", "latlng": LatLng(-6.200000, 106.816666)},
    {"name": "Kopiskuy Margonda", "latlng": LatLng(-6.210000, 106.820000)},
    {"name": "Kopiskuy UI", "latlng": LatLng(-6.220000, 106.830000)},
  ];

  String info = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initLocation();
  }

  // 🔥 MASTER FUNCTION (ANTI ERROR)
  Future<void> initLocation() async {
    try {
      // 1️⃣ CEK GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showMsg("Aktifkan GPS terlebih dahulu");
        setState(() => isLoading = false);
        return;
      }

      // 2️⃣ CEK PERMISSION
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        showMsg("Permission ditolak permanen. Aktifkan di settings.");
        setState(() => isLoading = false);
        return;
      }

      // 3️⃣ AMBIL LOKASI (REALTIME)
      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10), // ⏱ anti hang
        );
      } catch (e) {
        // 4️⃣ FALLBACK (JIKA TIMEOUT)
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        showMsg("Lokasi tidak ditemukan");
        setState(() => isLoading = false);
        return;
      }

      if (!mounted) return;

      userLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        isLoading = false;
      });

      // 5️⃣ MOVE MAP
      mapController.move(userLocation!, 15);
    } catch (e) {
      showMsg("Error ambil lokasi: $e");
      setState(() => isLoading = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 📏 HITUNG JARAK
  void calculateDistance(LatLng shop, String name) {
    final Distance distance = const Distance();

    double meter = distance(userLocation!, shop);
    double km = meter / 1000;

    double time = km / 40; // kecepatan 40km/jam
    int minutes = (time * 60).round();

    setState(() {
      info = "$name\n📍 ${km.toStringAsFixed(2)} km\n⏱ $minutes menit";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        title: const Text("Lokasi Kopiskuy ☕"),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userLocation == null
          ? const Center(child: Text("Lokasi tidak tersedia"))
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: userLocation!,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.tugasakhir',
                    ),

                    MarkerLayer(
                      markers: [
                        // 👤 USER
                        Marker(
                          point: userLocation!,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 45,
                          ),
                        ),

                        // ☕ COFFEE
                        ...coffeeShops.map(
                          (shop) => Marker(
                            point: shop["latlng"],
                            width: 80,
                            height: 80,
                            child: GestureDetector(
                              onTap: () {
                                calculateDistance(shop["latlng"], shop["name"]);
                              },
                              child: const Icon(
                                Icons.local_cafe,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 📦 INFO CARD
                if (info.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(info),
                    ),
                  ),
              ],
            ),
    );
  }
}
