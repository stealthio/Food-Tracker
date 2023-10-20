import 'package:hive/hive.dart';

import '../models/food_item.dart';


class FoodService {
  static final String _boxName = "foodBox";

  static void initHive() {
    Hive.registerAdapter(FoodItemAdapter());
  }

  static List<FoodItem> getAllFoodItems() {
    var box = Hive.box<FoodItem>(_boxName);
    return box.values.toList();
  }

  static void addFoodItem(FoodItem item) {
    var box = Hive.box<FoodItem>(_boxName);
    box.add(item);
  }

  static void updateFoodItem(FoodItem oldItem, FoodItem newItem) {
    var box = Hive.box<FoodItem>(_boxName);
    int? key = box.keys.firstWhere((k) => box.get(k) == oldItem, orElse: () => null);
    if (key != null) {
      box.put(key, newItem);
    }
  }

  static void removeFoodItem(FoodItem item) {
    var box = Hive.box<FoodItem>(_boxName);
    var key =
        box.keys.firstWhere((k) => box.get(k) == item, orElse: () => null);
    if (key != null) {
      box.delete(key);
    }
  }
}
