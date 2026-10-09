class ListItem {
  final String id;
  final String listId;
  String name;
  double quantity;
  String unit;
  bool isChecked;
  String? note;
  int version;

  ListItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isChecked,
    this.note,
    required this.version,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      name: json['name'] as String,
      quantity: double.tryParse(json['quantity'].toString()) ?? 1.0,
      unit: (json['unit'] as String?) ?? 'pieces',
      isChecked: json['is_checked'] as bool? ?? false,
      note: json['note'] as String?,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_checked': isChecked,
      'note': note,
      'version': version,
    };
  }
}
