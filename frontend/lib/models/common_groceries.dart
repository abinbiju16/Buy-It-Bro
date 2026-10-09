class PredefinedGroceryItem {
  final String name;
  final double defaultQuantity;
  final String defaultUnit;
  final String category;
  final String emoji;

  const PredefinedGroceryItem({
    required this.name,
    required this.defaultQuantity,
    required this.defaultUnit,
    required this.category,
    required this.emoji,
  });
}

class CommonGroceries {
  static const List<PredefinedGroceryItem> items = [
    // Dairy & Eggs
    PredefinedGroceryItem(name: 'Milk', defaultQuantity: 2, defaultUnit: 'packets', category: 'Dairy & Eggs', emoji: '🥛'),
    PredefinedGroceryItem(name: 'Eggs', defaultQuantity: 12, defaultUnit: 'pieces', category: 'Dairy & Eggs', emoji: '🥚'),
    PredefinedGroceryItem(name: 'Butter', defaultQuantity: 1, defaultUnit: 'packets', category: 'Dairy & Eggs', emoji: '🧈'),
    PredefinedGroceryItem(name: 'Cheese', defaultQuantity: 1, defaultUnit: 'packets', category: 'Dairy & Eggs', emoji: '🧀'),
    PredefinedGroceryItem(name: 'Yogurt / Curd', defaultQuantity: 1, defaultUnit: 'packets', category: 'Dairy & Eggs', emoji: '🥣'),

    // Produce & Veggies
    PredefinedGroceryItem(name: 'Onions', defaultQuantity: 2, defaultUnit: 'kg', category: 'Produce', emoji: '🧅'),
    PredefinedGroceryItem(name: 'Tomatoes', defaultQuantity: 1, defaultUnit: 'kg', category: 'Produce', emoji: '🍅'),
    PredefinedGroceryItem(name: 'Potatoes', defaultQuantity: 2, defaultUnit: 'kg', category: 'Produce', emoji: '🥔'),
    PredefinedGroceryItem(name: 'Bananas', defaultQuantity: 6, defaultUnit: 'pieces', category: 'Produce', emoji: '🍌'),
    PredefinedGroceryItem(name: 'Apples', defaultQuantity: 1, defaultUnit: 'kg', category: 'Produce', emoji: '🍎'),
    PredefinedGroceryItem(name: 'Garlic', defaultQuantity: 250, defaultUnit: 'g', category: 'Produce', emoji: '🧄'),

    // Pantry Essentials
    PredefinedGroceryItem(name: 'Rice', defaultQuantity: 5, defaultUnit: 'kg', category: 'Pantry', emoji: '🌾'),
    PredefinedGroceryItem(name: 'Bread', defaultQuantity: 1, defaultUnit: 'packets', category: 'Pantry', emoji: '🍞'),
    PredefinedGroceryItem(name: 'Cooking Oil', defaultQuantity: 1, defaultUnit: 'litres', category: 'Pantry', emoji: '🫗'),
    PredefinedGroceryItem(name: 'Wheat Flour / Atta', defaultQuantity: 5, defaultUnit: 'kg', category: 'Pantry', emoji: '🌾'),
    PredefinedGroceryItem(name: 'Sugar', defaultQuantity: 1, defaultUnit: 'kg', category: 'Pantry', emoji: '🧂'),
    PredefinedGroceryItem(name: 'Salt', defaultQuantity: 1, defaultUnit: 'packets', category: 'Pantry', emoji: '🧂'),
    PredefinedGroceryItem(name: 'Pasta', defaultQuantity: 1, defaultUnit: 'packets', category: 'Pantry', emoji: '🍝'),

    // Beverages & Snacks
    PredefinedGroceryItem(name: 'Tea / Chai', defaultQuantity: 1, defaultUnit: 'packets', category: 'Beverages', emoji: '☕'),
    PredefinedGroceryItem(name: 'Coffee', defaultQuantity: 1, defaultUnit: 'packets', category: 'Beverages', emoji: '☕'),
    PredefinedGroceryItem(name: 'Biscuits / Cookies', defaultQuantity: 2, defaultUnit: 'packets', category: 'Snacks', emoji: '🍪'),

    // Cleaning & Household
    PredefinedGroceryItem(name: 'Dish Soap', defaultQuantity: 1, defaultUnit: 'bottles', category: 'Household', emoji: '🧼'),
    PredefinedGroceryItem(name: 'Laundry Detergent', defaultQuantity: 1, defaultUnit: 'packets', category: 'Household', emoji: '🧺'),
    PredefinedGroceryItem(name: 'Toothpaste', defaultQuantity: 1, defaultUnit: 'pieces', category: 'Household', emoji: '🪥'),
  ];
}
