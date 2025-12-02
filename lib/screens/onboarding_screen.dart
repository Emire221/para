import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../widgets/glass_container.dart';
import '../services/data_service.dart';
import '../services/firebase_storage_service.dart';
import '../models/models.dart';
import '../core/providers/user_provider.dart';
import 'main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final DataService _dataService = DataService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  int _currentPage = 0;
  int _selectedAvatarIndex = -1;
  String? _selectedClass;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedSchool; // Okul Adı
  String? _selectedSchoolId; // Okul ID

  final TextEditingController _nameController = TextEditingController();

  List<String> _cities = [];
  List<String> _districts = [];
  List<School> _schools = []; // Filtrelenmiş okullar
  List<School> _allSchoolsInCity = []; // İldeki tüm okullar

  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadCityList();
  }

  Future<void> _loadCityList() async {
    final cities = await _dataService.getCities();
    setState(() {
      _cities = cities;
    });
  }

  Future<void> _onCitySelected(String cityName) async {
    setState(() {
      _selectedCity = cityName;
      _selectedDistrict = null;
      _selectedSchool = null;
      _selectedSchoolId = null;
      _districts = [];
      _schools = [];
      _isLoadingLocation = true;
    });

    // İlgili ilin okul verilerini indir/oku
    final schoolData = await _storageService.downloadSchoolData(cityName);

    // İlçeleri çıkar
    final uniqueDistricts = <String>{};
    for (var item in schoolData) {
      uniqueDistricts.add(item.ilce);
    }

    setState(() {
      _isLoadingLocation = false;
      _allSchoolsInCity = schoolData;
      _districts = uniqueDistricts.toList()..sort();
    });
  }

  void _onDistrictSelected(String districtName) {
    setState(() {
      _selectedDistrict = districtName;
      _selectedSchool = null;
      _selectedSchoolId = null;

      // Okulları filtrele
      _schools = _allSchoolsInCity
          .where((element) => element.ilce == districtName)
          .toList();

      // Okulları isme göre sırala
      _schools.sort((a, b) => a.okulAdi.compareTo(b.okulAdi));
    });
  }

  Future<void> _completeOnboarding() async {
    // Validasyon
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen adınızı girin')));
      return;
    }

    if (_selectedAvatarIndex == -1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir avatar seçin')));
      return;
    }

    if (_selectedClass == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen sınıfınızı seçin')));
      return;
    }

    if (_selectedCity == null ||
        _selectedDistrict == null ||
        _selectedSchool == null ||
        _selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen okul bilgilerinizi tam olarak doldurun'),
        ),
      );
      return;
    }

    // Kullanıcı bilgilerini kaydet
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      await ref
          .read(userRepositoryProvider)
          .saveUserProfile(
            userId: userId,
            name: _nameController.text,
            grade: _selectedClass!,
            city: _selectedCity!,
            district: _selectedDistrict!,
            schoolId: _selectedSchoolId!,
            schoolName: _selectedSchool!,
            avatar:
                'assets/images/avatar.png', // Avatar indexine göre path belirlenebilir ama şimdilik sabit veya logic eklenebilir
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt yapılırken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298), Color(0xFF7e22ce)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Logo and Title
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.asset(
                        'assets/animation/loading-kum.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'BİLGİ AVCISI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCurrentPageTitle(),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Page Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Content Area
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildAvatarSelection(),
                    _buildClassSelection(),
                    _buildLocationSelection(),
                  ],
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back),
                            SizedBox(width: 8),
                            Text('Geri'),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1e3c72),
                        elevation: 8,
                        shadowColor: Colors.white.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Başla' : 'İleri',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == 2
                                ? Icons.check
                                : Icons.arrow_forward,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Kendini Tanıt';
      case 1:
        return 'Sınıfını Seç';
      case 2:
        return 'Okul Bilgilerin';
      default:
        return '';
    }
  }

  Widget _buildAvatarSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Adını Yaz',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Avatarını Seç',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(6, (index) {
              final colors = [
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.pink,
                Colors.purple,
                Colors.teal,
              ];
              final icons = [
                Icons.person,
                Icons.face,
                Icons.emoji_emotions,
                Icons.sentiment_very_satisfied,
                Icons.child_care,
                Icons.school,
              ];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatarIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: _selectedAvatarIndex == index
                        ? LinearGradient(
                            colors: [
                              colors[index],
                              colors[index].withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                    color: _selectedAvatarIndex != index
                        ? Colors.white.withValues(alpha: 0.2)
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedAvatarIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      width: _selectedAvatarIndex == index ? 3 : 2,
                    ),
                    boxShadow: _selectedAvatarIndex == index
                        ? [
                            BoxShadow(
                              color: colors[index].withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icons[index], size: 45, color: Colors.white),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 80, color: Colors.white),
          const SizedBox(height: 40),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedClass,
                dropdownColor: const Color(0xFF1e3c72),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                hint: const Text(
                  'Sınıfını Seç',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                items:
                    [
                          '3. Sınıf',
                          '4. Sınıf',
                          '5. Sınıf',
                          '6. Sınıf',
                          '7. Sınıf',
                          '8. Sınıf',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 60, color: Colors.white),
            const SizedBox(height: 32),
            // İL SEÇİMİ
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCity,
                  dropdownColor: const Color(0xFF1e3c72),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  hint: const Text(
                    'İl Seçiniz',
                    style: TextStyle(color: Colors.white70),
                  ),
                  items: _cities.map<DropdownMenuItem<String>>((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onCitySelected(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingLocation)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            else ...[
              // İLÇE SEÇİMİ
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    dropdownColor: const Color(0xFF1e3c72),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    hint: const Text(
                      'İlçe Seçiniz',
                      style: TextStyle(color: Colors.white70),
                    ),
                    items: _districts.map<DropdownMenuItem<String>>((district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _onDistrictSelected(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // OKUL SEÇİMİ
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSchool,
                    dropdownColor: const Color(0xFF1e3c72),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    hint: const Text(
                      'Okul Seçiniz',
                      style: TextStyle(color: Colors.white70),
                    ),
                    items: _schools.map<DropdownMenuItem<String>>((school) {
                      return DropdownMenuItem<String>(
                        value: school.okulAdi,
                        child: Text(
                          school.okulAdi,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSchool = value;
                        // ID'yi bul
                        final school = _schools.firstWhere(
                          (s) => s.okulAdi == value,
                        );
                        _selectedSchoolId = school.okulID;
                      });
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
