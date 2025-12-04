import 'package:flutter/foundation.dart';
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
      if (kDebugMode) debugPrint('Sınıf listesi yüklenemedi: $e');
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
      _filteredSchools = [];
      _isLoading = true;
      _loadingMessage = 'Okullar yükleniyor...';
    });

    try {
      final schools = await FirebaseStorageService().downloadSchoolData(city);
      // İlçeleri normalize ederek karşılaştır ve benzersiz olanları al
      final districtsSet = <String>{};
      for (final school in schools) {
        final normalizedDistrict = school.ilce.trim();
        if (normalizedDistrict.isNotEmpty) {
          districtsSet.add(normalizedDistrict);
        }
      }
      final districts = districtsSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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
      // Büyük/küçük harf duyarsız karşılaştırma
      _filteredSchools = _schools.where((s) => 
        s.ilce.toLowerCase().trim() == district.toLowerCase().trim()
      ).toList()
        ..sort((a, b) => a.okulAdi.toLowerCase().compareTo(b.okulAdi.toLowerCase()));
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
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
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

                    // İlçe Seçimi (Arama özellikli)
                    _buildSearchableField(
                      label: _selectedDistrict ?? 'İlçe Seçiniz',
                      icon: Icons.map,
                      enabled: _selectedCity != null,
                      onTap: _selectedCity == null ? null : _showDistrictPicker,
                    ),
                    const SizedBox(height: 16),

                    // Okul Seçimi (Arama özellikli)
                    _buildSearchableField(
                      label: _selectedSchoolID != null
                          ? _filteredSchools.firstWhere(
                              (s) => s.okulID == _selectedSchoolID,
                              orElse: () => School(okulID: '', okulAdi: 'Okul Seçiniz', il: '', ilce: ''),
                            ).okulAdi
                          : 'Okul Seçiniz',
                      icon: Icons.school,
                      enabled: _selectedDistrict != null,
                      onTap: _selectedDistrict == null ? null : _showSchoolPicker,
                    ),
                    const SizedBox(height: 16),

                    // Sınıf Seçimi
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
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

  /// Arama özellikli seçim alanı
  Widget _buildSearchableField({
    required String label,
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? Colors.white : Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white54,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: enabled ? Colors.white : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  /// İlçe seçici dialog
  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchablePickerSheet<String>(
        title: 'İlçe Seçiniz',
        items: _districts,
        itemBuilder: (district) => district,
        searchMatcher: (district, query) =>
            district.toLowerCase().contains(query.toLowerCase()),
        onSelected: (district) {
          Navigator.pop(context);
          _onDistrictChanged(district);
        },
      ),
    );
  }

  /// Okul seçici dialog
  void _showSchoolPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchablePickerSheet<School>(
        title: 'Okul Seçiniz',
        items: _filteredSchools,
        itemBuilder: (school) => school.okulAdi,
        searchMatcher: (school, query) =>
            school.okulAdi.toLowerCase().contains(query.toLowerCase()),
        onSelected: (school) {
          Navigator.pop(context);
          setState(() => _selectedSchoolID = school.okulID);
        },
      ),
    );
  }
}

/// Arama özellikli seçici bottom sheet
class _SearchablePickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemBuilder;
  final bool Function(T, String) searchMatcher;
  final void Function(T) onSelected;

  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.searchMatcher,
    required this.onSelected,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() => _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => widget.searchMatcher(item, query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF11998e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Tutacak
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Arama alanı
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        title: Text(
                          widget.itemBuilder(item),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => widget.onSelected(item),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}