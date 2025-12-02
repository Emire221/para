import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/glass_container.dart';
import '../services/firebase_storage_service.dart';
import '../models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/sync_provider.dart';
import '../features/mascot/presentation/screens/pet_selection_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedSchoolID;
  String? _selectedClass;

  List<String> _cities = [];
  List<School> _schools = [];
  List<String> _districts = [];
  List<School> _filteredSchools = [];
  List<Map<String, String>> _classes = [];

  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCities();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/siniflar.json',
      );
      final data = await json.decode(response);
      setState(() {
        _classes = (data['siniflar'] as List).map((e) {
          return {'id': e['id'].toString(), 'name': e['name'].toString()};
        }).toList();
      });
    } catch (e) {
      debugPrint('Sınıf listesi yüklenemedi: $e');
    }
  }

  Future<void> _loadCities() async {
    final String response = await rootBundle.loadString(
      'assets/json/cities.json',
    );
    final data = await json.decode(response);
    setState(() {
      _cities = List<String>.from(data['cities']);
    });
  }

  Future<void> _onCityChanged(String? city) async {
    if (city == null) return;

    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedSchoolID = null;
      _isLoading = true;
      _loadingMessage = 'Okullar yükleniyor...';
    });

    try {
      final schools = await FirebaseStorageService().downloadSchoolData(city);
      final districts = schools.map((e) => e.ilce).toSet().toList()..sort();

      if (mounted) {
        setState(() {
          _schools = schools;
          _districts = districts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Okul listesi yüklenemedi: $e')));
      }
    }
  }

  void _onDistrictChanged(String? district) {
    if (district == null) return;

    setState(() {
      _selectedDistrict = district;
      _selectedSchoolID = null;
      _filteredSchools = _schools.where((s) => s.ilce == district).toList();
    });
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null ||
        _selectedDistrict == null ||
        _selectedSchoolID == null ||
        _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Profil kaydediliyor...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final selectedSchool = _schools.firstWhere(
        (s) => s.okulID == _selectedSchoolID,
      );

      // 1. Profili Firestore'a kaydet
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'city': _selectedCity,
        'district': _selectedDistrict,
        'schoolID': _selectedSchoolID,
        'schoolName': selectedSchool.okulAdi,
        'classLevel': _selectedClass,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. İçerikleri indir
      setState(() {
        _loadingMessage = 'Ders içerikleri senkronize ediliyor...';
      });

      // Sınıf adını normalize et (örn: "3. Sınıf" -> "3_Sinif")
      final safeClassName = _selectedClass!
          .replaceAll('.', '')
          .replaceAll(' ', '_')
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'I');

      // Sync işlemini başlat
      await ref
          .read(syncControllerProvider.notifier)
          .syncContent(safeClassName);

      // Hata kontrolü
      final syncState = ref.read(syncControllerProvider);
      if (syncState.error != null) {
        throw Exception(syncState.error);
      }

      // 3. Yönlendir
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PetSelectionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Profil Kurulumu',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // İsim
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Ad Soyad', Icons.person),
                      validator: (v) => v?.isEmpty ?? true ? 'Gerekli' : null,
                    ),
                    const SizedBox(height: 16),

                    // Yaş
                    TextFormField(
                      controller: _ageController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Yaş', Icons.calendar_today),
                      validator: (v) => v?.isEmpty ?? true ? 'Gerekli' : null,
                    ),
                    const SizedBox(height: 16),

                    // İl Seçimi
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      dropdownColor: const Color(0xFF11998e),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        'İl Seçiniz',
                        Icons.location_city,
                      ),
                      items: _cities
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: _onCityChanged,
                    ),
                    const SizedBox(height: 16),

                    // İlçe Seçimi
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      dropdownColor: const Color(0xFF11998e),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('İlçe Seçiniz', Icons.map),
                      items: _districts
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: _selectedCity == null
                          ? null
                          : _onDistrictChanged,
                    ),
                    const SizedBox(height: 16),

                    // Okul Seçimi
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSchoolID,
                      dropdownColor: const Color(0xFF11998e),
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      decoration: _inputDecoration(
                        'Okul Seçiniz',
                        Icons.school,
                      ),
                      items: _filteredSchools
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.okulID,
                              child: Text(
                                s.okulAdi,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _selectedDistrict == null
                          ? null
                          : (v) => setState(() => _selectedSchoolID = v),
                    ),
                    const SizedBox(height: 16),

                    // Sınıf Seçimi
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      dropdownColor: const Color(0xFF11998e),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        'Sınıf Seçiniz',
                        Icons.class_,
                      ),
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['name']!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedClass = v),
                    ),

                    const SizedBox(height: 32),

                    if (_isLoading)
                      Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _loadingMessage,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: _completeSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF11998e),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kurulumu Tamamla',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
