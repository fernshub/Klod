import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WazeCloneApp());
}

class WazeCloneApp extends StatelessWidget {
  const WazeCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Waze Clone - Complete MVP',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
      ),
      home: const CompleteMapScreen(),
    );
  }
}

class CompleteMapScreen extends StatefulWidget {
  const CompleteMapScreen({super.key});

  @override
  State<CompleteMapScreen> createState() => _CompleteMapScreenState();
}

class _CompleteMapScreenState extends State<CompleteMapScreen> {
  LatLng _currentPosition = const LatLng(33.3152, 44.3661); // نقطة افتراضية (بغداد)
  bool _locationInitialized = false;
  final MapController _mapController = MapController();
  final List<String> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadSavedReports(); // تحميل البلاغات المحفوظة سابقاً
    _initGPS();          // تفعيل الـ GPS
  }

  // 1. استرجاع البلاغات المحفوظة محلياً لكي لا تختفي عند إعادة فتح التطبيق
  Future<void> _loadSavedReports() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? saved = prefs.getStringList('saved_reports');
      if (saved != null) {
        _reports.addAll(saved);
      }
    });
  }

  // 2. حفظ البلاغات الجديدة محلياً
  Future<void> _saveReportsToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_reports', _reports);
  }

  // 3. تفعيل الـ GPS والتتبع الحي لموقع المستخدم
  Future<void> _initGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      LatLng newPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPoint;
        if (!_locationInitialized) {
          _locationInitialized = true;
          _mapController.move(newPoint, 16.0); // تحريك الخريطة لموقعك تلقائياً عند فتحه
        }
      });
    });
  }

  // 4. دالة إضافة وحفظ بلاغ جديد
  void _addReport() {
    String newReportText = "⚠️ بلاغ حادث في إحداثيات: ${_currentPosition.latitude.toStringAsFixed(3)}, ${_currentPosition.longitude.toStringAsFixed(3)}";
    setState(() {
      _reports.add(newReportText);
    });
    _saveReportsToDevice(); // حفظ القائمة محلياً

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تسجيل وحفظ البلاغ بنجاح!'),
        backgroundColor: Colors.amber,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق Waze مصغر - النسخة المتكاملة'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          // عرض الخريطة التفاعلية
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.waze_clone',
              ),
            ],
          ),
          // شريط علوي لعرض آخر بلاغ مروري تم تسجيلة
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                _reports.isNotEmpty ? _reports.last : '📡 نظام البلاغات جاهز.. لا توجد بلاغات حالياً.',
                style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      // زر إضافة بلاغ عائم
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReport,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.warning, color: Colors.black),
        label: const Text(
          'بلاغ عن حادث',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
