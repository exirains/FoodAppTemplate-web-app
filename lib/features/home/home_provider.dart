import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../models/bread.dart';
import '../../models/category.dart';
import '../../services/bread_repository.dart';
import '../../services/lifecycle_service.dart';
import '../../core/localization/locale_provider.dart';
import '../auth/auth_provider.dart';

final breadRepositoryProvider = Provider((ref) => BreadRepository());

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  // Babka Bakery Categories
  return const [
    Category(
      id: 'ekmekler',
      name: 'Ekmekler',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
      translations: {'tr': 'Ekmekler', 'en': 'Breads'},
    ),
    Category(
      id: 'kekler',
      name: 'Kekler',
      imageUrl: 'https://images.unsplash.com/photo-1519915028121-7d3463d20b13?w=400',
      translations: {'tr': 'Kekler', 'en': 'Cakes'},
    ),
    Category(
      id: 'pasta',
      name: 'Pasta',
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
      translations: {'tr': 'Pasta', 'en': 'Pastries'},
    ),
    Category(
      id: 'kurabiye',
      name: 'Kurabiye',
      imageUrl: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=400',
      translations: {'tr': 'Kurabiye', 'en': 'Cookies'},
    ),
    Category(
      id: 'corekler',
      name: 'Çörekler',
      imageUrl: 'https://images.unsplash.com/photo-1586444248902-2f64eddf13cf?w=400',
      translations: {'tr': 'Çörekler', 'en': 'Buns'},
    ),
    Category(
      id: 'specialty-babka',
      name: 'Specialty Babka',
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
      translations: {'tr': 'Specialty Babka', 'en': 'Specialty Babka'},
    ),
  ];
});

final breadsProvider = StreamProvider<List<Bread>>((ref) {
  final selectedId = ref.watch(selectedCategoryIdProvider);
  
  // Return mock data for the selected category
  final mockBreads = [
    Bread(
      id: 'b1',
      categoryId: 'ekmekler',
      name: 'Ekşi Mayalı Ekmek',
      description: 'Artisanal sourdough bread with a crunchy crust.',
      price: 45.0,
      imageUrl: 'https://images.unsplash.com/photo-1585478259715-876a6a81fc08?w=800',
      tag: 'FRESH',
      translations: {'tr': {'name': 'Ekşi Mayalı Ekmek', 'description': 'Çıtır kabuklu zanaatkar ekşi maya ekmeği.'}},
    ),
    Bread(
      id: 'b2',
      categoryId: 'specialty-babka',
      name: 'Çikolatalı Babka',
      description: 'Signature chocolate swirl babka.',
      price: 120.0,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
      tag: 'BEST SELLER',
      translations: {'tr': {'name': 'Çikolatalı Babka', 'description': 'İmza çikolata dolgulu babka.'}},
    ),
    Bread(
      id: 'b3',
      categoryId: 'kekler',
      name: 'Limonlu Kek',
      description: 'Zesty lemon cake with glaze.',
      price: 85.0,
      imageUrl: 'https://images.unsplash.com/photo-1519915028121-7d3463d20b13?w=800',
      translations: {'tr': {'name': 'Limonlu Kek', 'description': 'Limon aromalı ve sır kaplı kek.'}},
    ),
    Bread(
      id: 'b4',
      categoryId: 'kurabiye',
      name: 'Damla Çikolatalı Kurabiye',
      description: 'Soft and chewy chocolate chip cookies.',
      price: 35.0,
      imageUrl: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=800',
      translations: {'tr': {'name': 'Damla Çikolatalı Kurabiye', 'description': 'Yumuşak ve bol çikolatalı kurabiyeler.'}},
    ),
  ];

  if (selectedId == null) return Stream.value(mockBreads);
  return Stream.value(mockBreads.where((b) => b.categoryId == selectedId).toList());
});

final filteredBreadsProvider = Provider<AsyncValue<List<Bread>>>((ref) {
  return ref.watch(breadsProvider);
});

final popularBreadsProvider = StreamProvider<List<Bread>>((ref) {
  // Mock popular items
  return Stream.value([
    const Bread(
      id: 'b2',
      categoryId: 'specialty-babka',
      name: 'Çikolatalı Babka',
      description: 'Signature chocolate swirl babka.',
      price: 120.0,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
      tag: 'BEST SELLER',
      translations: {'tr': {'name': 'Çikolatalı Babka', 'description': 'İmza çikolata dolgulu babka.'}},
    ),
  ]);
});

final filteredPopularBreadsProvider = Provider<AsyncValue<List<Bread>>>((ref) {
  final popularAsync = ref.watch(popularBreadsProvider);
  final selectedId = ref.watch(selectedCategoryIdProvider);

  if (selectedId == null) return popularAsync;

  return popularAsync.whenData((breads) {
    return breads.where((bread) => bread.categoryId == selectedId).toList();
  });
});
