import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Institution {
  final String id;
  final String name;
  final String city;
  final String district;
  final String? neighborhood;
  final InstitutionType type;

  const Institution({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    this.neighborhood,
    required this.type,
  });

  @override
  String toString() => name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'district': district,
    'neighborhood': neighborhood,
    'type': type.name,
  };

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: json['id'],
    name: json['name'],
    city: json['city'],
    district: json['district'],
    neighborhood: json['neighborhood'],
    type: InstitutionType.values.firstWhere((e) => e.name == json['type']),
  );

  // Factory method to create from YSK dataset format
  factory Institution.fromYskData(Map<String, dynamic> yskData, String id) {
    final schoolName = yskData['school_name'] as String;
    final cityName = yskData['city_name'] as String;
    final districtName = yskData['district_name'] as String;
    final neighborhoodName = yskData['neighborhood_name'] as String?;
    
    // Determine type based on school name
    InstitutionType type;
    if (schoolName.toUpperCase().contains('DERSHANE') || 
        schoolName.toUpperCase().contains('ETÜT') ||
        schoolName.toUpperCase().contains('KURS')) {
      type = InstitutionType.dershane;
    } else {
      type = InstitutionType.lise;
    }

    return Institution(
      id: id,
      name: schoolName,
      city: cityName,
      district: districtName.replaceAll(' MERKEZ', '').trim(),
      neighborhood: neighborhoodName,
      type: type,
    );
  }
}

enum InstitutionType {
  lise('Lise'),
  dershane('Dershane');

  const InstitutionType(this.displayName);
  final String displayName;
}

class InstitutionData {
  static List<Institution>? _cachedInstitutions;
  static bool _isLoading = false;

  // Load institutions from multiple sources (YSK + Fen Liseleri supplement)
  static Future<List<Institution>> get allInstitutions async {
    if (_cachedInstitutions != null) {
      return _cachedInstitutions!;
    }

    if (_isLoading) {
      // Wait for loading to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedInstitutions ?? [];
    }

    _isLoading = true;
    
    try {
      final allInstitutions = <Institution>[];
      final seenNames = <String>{};
      
      // 1. Load Fen Liseleri supplement first (higher priority)
      try {
        final String fenData = await rootBundle.loadString('assets/data/fen_liseleri_supplement.json');
        final List<dynamic> fenList = json.decode(fenData);
        
        for (final item in fenList) {
          final institution = Institution.fromJson(item);
          final uniqueKey = '${institution.name}_${institution.city}_${institution.district}';
          
          if (!seenNames.contains(uniqueKey)) {
            seenNames.add(uniqueKey);
            allInstitutions.add(institution);
          }
        }
        debugPrint('Loaded ${allInstitutions.length} Fen Liseleri from supplement');
      } catch (e) {
        debugPrint('Error loading Fen Liseleri supplement: $e');
      }
      
      // 2. Load YSK dataset (filtered for high schools only)
      try {
        final String yskData = await rootBundle.loadString('assets/data/ysk_school_list.json');
        final List<dynamic> jsonList = json.decode(yskData);
        
        int yskAdded = 0;
        for (int i = 0; i < jsonList.length; i++) {
          try {
            final item = jsonList[i] as Map<String, dynamic>;
            final schoolName = item['school_name'] as String?;
            
            if (schoolName != null && _isEducationalInstitution(schoolName)) {
              final institution = Institution.fromYskData(item, 'ysk_$i');
              final uniqueKey = '${institution.name}_${institution.city}_${institution.district}';
              
              // Add only if not already present
              if (!seenNames.contains(uniqueKey)) {
                seenNames.add(uniqueKey);
                allInstitutions.add(institution);
                yskAdded++;
              }
            }
          } catch (e) {
            continue; // Skip invalid entries
          }
        }
        debugPrint('Added $yskAdded high schools from YSK dataset');
      } catch (e) {
        debugPrint('Error loading YSK dataset: $e');
      }
      
      // Sort by name for better user experience
      allInstitutions.sort((a, b) => a.name.compareTo(b.name));
      
      debugPrint('Total institutions loaded: ${allInstitutions.length}');
      debugPrint('High schools: ${allInstitutions.where((i) => i.type == InstitutionType.lise).length}');
      debugPrint('Study centers: ${allInstitutions.where((i) => i.type == InstitutionType.dershane).length}');
      
      _cachedInstitutions = allInstitutions.isNotEmpty ? allInstitutions : _getFallbackInstitutions();
      return _cachedInstitutions!;
    } catch (e) {
      debugPrint('Critical error loading institutions: $e');
      // Fallback to a minimal dataset if loading fails
      _cachedInstitutions = _getFallbackInstitutions();
      return _cachedInstitutions!;
    } finally {
      _isLoading = false;
    }
  }

  // Filter function to identify ONLY high schools and dershanes
  static bool _isEducationalInstitution(String schoolName) {
    final name = schoolName.toUpperCase();
    
    // EXCLUDE primary and middle schools first
    if (name.contains('İLKOKULU') || 
        name.contains('ORTAOKULU') ||
        name.contains('İLKÖĞRETİM')) {
      return false;
    }
    
    // EXCLUDE non-educational venues
    if (name.contains('CAMİ') ||
        name.contains('CEMEVI') ||
        name.contains('KAHVEHANE') ||
        name.contains('KAFE') ||
        name.contains('RESTAURANT') ||
        name.contains('DÜKKÂN') ||
        name.contains('MAĞAZA') ||
        name.contains('AVM') ||
        name.contains('PAZAR') ||
        name.contains('BAHÇE') ||
        name.contains('PARK') ||
        name.contains('MUHTARLIK') ||
        name.contains('APARTMAN') ||
        name.contains('SITE') ||
        name.contains('KONUT') ||
        name.contains('SALON') && !name.contains('OKUL')) {
      return false;
    }
    
    // ONLY INCLUDE high schools and study centers
    return name.contains('LİSESİ') ||           // All high schools
           name.contains('DERSHANE') ||         // Study centers
           name.contains('ETÜT') ||             // Study centers
           name.contains('KURS MERKEZİ') ||     // Course centers
           (name.contains('KOLEJ') &&           // Colleges (only if they're high schools)
            !name.contains('İLKOKUL') &&        // Make sure it's not primary
            !name.contains('ORTAOKUL'));        // Make sure it's not middle school
  }

  // Fallback institutions in case of loading failure
  static List<Institution> _getFallbackInstitutions() {
    return [
      Institution(id: 'fallback_01', name: 'Bolu Fen Lisesi', city: 'Bolu', district: 'Merkez', type: InstitutionType.lise),
      Institution(id: 'fallback_02', name: 'Bolu Anadolu Lisesi', city: 'Bolu', district: 'Merkez', type: InstitutionType.lise),
      Institution(id: 'fallback_03', name: 'İstanbul Fen Lisesi', city: 'İstanbul', district: 'Fatih', type: InstitutionType.lise),
      Institution(id: 'fallback_04', name: 'Ankara Fen Lisesi', city: 'Ankara', district: 'Çankaya', type: InstitutionType.lise),
      Institution(id: 'fallback_05', name: 'İzmir Fen Lisesi', city: 'İzmir', district: 'Bornova', type: InstitutionType.lise),
    ];
  }

  static Future<List<Institution>> searchInstitutions(String query) async {
    final institutions = await allInstitutions;
    
    if (query.trim().isEmpty) {
      // Return first 100 institutions for better performance
      return institutions.take(100).toList();
    }
    
    final lowercaseQuery = query.toLowerCase().trim();
    final results = institutions.where((institution) {
      return institution.name.toLowerCase().contains(lowercaseQuery) ||
             institution.city.toLowerCase().contains(lowercaseQuery) ||
             institution.district.toLowerCase().contains(lowercaseQuery) ||
             (institution.neighborhood?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             institution.type.displayName.toLowerCase().contains(lowercaseQuery);
    }).toList();
    
    // Limit results for performance
    return results.take(50).toList();
  }

  static Future<List<Institution>> getInstitutionsByType(InstitutionType type) async {
    final institutions = await allInstitutions;
    return institutions.where((institution) => institution.type == type).take(100).toList();
  }

  static Future<List<Institution>> getInstitutionsByCity(String city) async {
    final institutions = await allInstitutions;
    return institutions.where((institution) => 
      institution.city.toLowerCase() == city.toLowerCase()).take(100).toList();
  }

  static Future<List<String>> get cities async {
    final institutions = await allInstitutions;
    return institutions.map((e) => e.city).toSet().toList()..sort();
  }

  static Future<Institution?> getInstitutionById(String id) async {
    final institutions = await allInstitutions;
    try {
      return institutions.firstWhere((institution) => institution.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper method to check if an institution exists by name
  static Future<bool> institutionExists(String name) async {
    final institutions = await allInstitutions;
    return institutions.any((institution) => 
      institution.name.toLowerCase() == name.toLowerCase());
  }

  // Get suggestions for similar institution names
  static Future<List<Institution>> getSimilarInstitutions(String query) async {
    if (query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase().trim();
    final institutions = await allInstitutions;
    final suggestions = <Institution>[];
    
    // Exact matches first
    for (final institution in institutions) {
      if (institution.name.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(institution);
        if (suggestions.length >= 10) break;
      }
    }
    
    return suggestions;
  }

  // Get total count of institutions
  static Future<int> get totalCount async {
    final institutions = await allInstitutions;
    return institutions.length;
  }

  // Get institutions by type with count
  static Future<Map<InstitutionType, int>> get institutionCountsByType async {
    final institutions = await allInstitutions;
    final counts = <InstitutionType, int>{};
    
    for (final type in InstitutionType.values) {
      counts[type] = institutions.where((inst) => inst.type == type).length;
    }
    
    return counts;
  }
} 