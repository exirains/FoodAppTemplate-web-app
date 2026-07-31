import '../models/bread.dart';
import '../models/category.dart';
import '../core/design_system/sangak_tokens.dart';

class BreadRepository {
  Future<List<Category>> getCategories() async {
    // Artificial delay
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      Category(id: '1', name: 'Traditional', imageUrl: 'https://images.unsplash.com/photo-1598373182133-52452f7691ef?q=80&w=400'),
      Category(id: '2', name: 'Whole Wheat', imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=400'),
      Category(id: '3', name: 'Pastries', imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=400'),
      Category(id: '4', name: 'Specialty', imageUrl: 'https://images.unsplash.com/photo-1589367920969-ab8e0509aae2?q=80&w=400'),
    ];
  }

  Future<List<Bread>> getBreads() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      Bread(
        id: '1',
        title: 'Traditional Sangak',
        description: 'Stone-baked whole wheat flatbread, freshly made in our traditional oven.',
        price: 85.0,
        imageUrl: 'https://images.unsplash.com/photo-1598373182133-52452f7691ef?q=80&w=600',
        rating: 4.9,
        reviews: 124,
        freshness: SangakTokens.outOfOven,
        categoryId: '1',
      ),
      Bread(
        id: '2',
        title: 'Sesame Barbari',
        description: 'Thick, fluffy Persian flatbread topped with toasted sesame seeds.',
        price: 75.0,
        imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=600',
        rating: 4.8,
        reviews: 98,
        freshness: SangakTokens.freshToday,
        categoryId: '1',
      ),
      Bread(
        id: '3',
        title: 'Lavash Thin',
        description: 'Paper-thin, soft traditional flatbread, perfect for wraps and dips.',
        price: 45.0,
        imageUrl: 'https://images.unsplash.com/photo-1623334044303-24286c152431?q=80&w=600',
        rating: 4.7,
        reviews: 86,
        categoryId: '1',
      ),
      Bread(
        id: '4',
        title: 'Whole Grain Loaf',
        description: 'Dense, nutrient-rich sourdough loaf with a crispy crust.',
        price: 120.0,
        imageUrl: 'https://images.unsplash.com/photo-1589367920969-ab8e0509aae2?q=80&w=600',
        rating: 4.9,
        reviews: 45,
        freshness: SangakTokens.limitedQuantity,
        categoryId: '2',
      ),
    ];
  }
}
