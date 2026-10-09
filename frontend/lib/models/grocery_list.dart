import 'list_item.dart';

class GroceryList {
  final String id;
  String title;
  final String? ownerUserId;
  final String? groupId;
  int itemCount;
  int checkedCount;
  List<ListItem> items;

  GroceryList({
    required this.id,
    required this.title,
    this.ownerUserId,
    this.groupId,
    this.itemCount = 0,
    this.checkedCount = 0,
    this.items = const [],
  });

  bool get isShared => groupId != null;

  factory GroceryList.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<ListItem> parsedItems = rawItems
        .map((itemJson) => ListItem.fromJson(itemJson as Map<String, dynamic>))
        .toList();

    return GroceryList(
      id: json['id'] as String,
      title: json['title'] as String,
      ownerUserId: json['owner_user_id'] as String?,
      groupId: json['group_id'] as String?,
      itemCount: json['item_count'] as int? ?? parsedItems.length,
      checkedCount: json['checked_count'] as int? ??
          parsedItems.where((i) => i.isChecked).length,
      items: parsedItems,
    );
  }
}
