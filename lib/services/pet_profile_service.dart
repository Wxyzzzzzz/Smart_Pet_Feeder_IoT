class PetProfileService {
  static final PetProfileService _instance = PetProfileService._internal();
  factory PetProfileService() => _instance;
  PetProfileService._internal();

  // Pet profile data (in-memory storage, can be replaced with SharedPreferences or Firestore)
  String _petName = 'Fluffy';
  String _petBreed = 'Golden Retriever';
  double _petWeight = 25.0;
  int _petAge = 3;
  String _ageCategory = 'Adult';
  int _mealsPerDay = 2;
  double _dailyPortion = 625.0;
  double _portionPerMeal = 312.5;

  // Getters
  String get petName => _petName;
  String get petBreed => _petBreed;
  double get petWeight => _petWeight;
  int get petAge => _petAge;
  String get ageCategory => _ageCategory;
  int get mealsPerDay => _mealsPerDay;
  double get dailyPortion => _dailyPortion;
  double get portionPerMeal => _portionPerMeal;

  // Update pet profile
  void updateProfile({
    required String name,
    required String breed,
    required double weight,
    required int age,
    required String ageCategory,
    required int mealsPerDay,
    required double dailyPortion,
    required double portionPerMeal,
  }) {
    _petName = name;
    _petBreed = breed;
    _petWeight = weight;
    _petAge = age;
    _ageCategory = ageCategory;
    _mealsPerDay = mealsPerDay;
    _dailyPortion = dailyPortion;
    _portionPerMeal = portionPerMeal;

    print(
        '[PET_PROFILE] Updated: $name, ${portionPerMeal.toInt()}g per meal, ${dailyPortion.toInt()}g daily');
  }

  // Reset to defaults
  void resetToDefaults() {
    _petName = 'Fluffy';
    _petBreed = 'Golden Retriever';
    _petWeight = 25.0;
    _petAge = 3;
    _ageCategory = 'Adult';
    _mealsPerDay = 2;
    _dailyPortion = 625.0;
    _portionPerMeal = 312.5;
  }
}
