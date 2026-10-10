import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/grocery_list.dart';
import '../models/list_item.dart';
import '../models/group.dart';

class ApiService {
  final String token;

  ApiService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // --- Personal Lists ---
  Future<List<GroceryList>> getMyLists() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/me/lists'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => GroceryList.fromJson(json)).toList();
    }
    throw Exception('Failed to load private lists');
  }

  Future<GroceryList> createPersonalList(String title) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/me/lists'),
      headers: _headers,
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode == 201) {
      return GroceryList.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create private list');
  }

  // --- Groups ---
  Future<List<Group>> getGroups() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/groups'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Group.fromJson(json)).toList();
    }
    throw Exception('Failed to load groups');
  }

  Future<Group> createGroup(String name) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/groups'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      return Group.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create group');
  }

  Future<Group> getGroupDetails(String groupId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/groups/$groupId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Group.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load group details');
  }

  Future<Group> renameGroup(String groupId, String newName) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/groups/$groupId'),
      headers: _headers,
      body: jsonEncode({'name': newName.trim()}),
    );
    if (response.statusCode == 200) {
      return Group.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to rename group');
  }

  Future<void> deleteGroup(String groupId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/groups/$groupId'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete group');
    }
  }

  Future<String> createGroupInvitation(String groupId, {String role = 'MEMBER'}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/groups/$groupId/invitations'),
      headers: _headers,
      body: jsonEncode({'role': role, 'expires_in_days': 7}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'] as String;
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to create invitation');
  }

  Future<Group> acceptInvitation(String token) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/invitations/accept'),
      headers: _headers,
      body: jsonEncode({'token': token.trim()}),
    );
    if (response.statusCode == 200) {
      return Group.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to accept invitation');
  }

  Future<List<GroceryList>> getGroupLists(String groupId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/groups/$groupId/lists'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => GroceryList.fromJson(json)).toList();
    }
    throw Exception('Failed to load group lists');
  }

  Future<GroceryList> createGroupList(String groupId, String title) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/groups/$groupId/lists'),
      headers: _headers,
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode == 201) {
      return GroceryList.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create group list');
  }

  // --- Unified List Management ---
  Future<GroceryList> getList(String listId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/lists/$listId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return GroceryList.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to retrieve list');
  }

  Future<void> deleteList(String listId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/lists/$listId'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete list');
    }
  }

  Future<GroceryList> renameList(String listId, String newTitle) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/lists/$listId'),
      headers: _headers,
      body: jsonEncode({'title': newTitle.trim()}),
    );
    if (response.statusCode == 200) {
      return GroceryList.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to rename list');
  }

  // --- Items Management ---
  Future<ListItem> addItem({
    required String listId,
    required String name,
    required double quantity,
    required String unit,
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/lists/$listId/items'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'note': note,
      }),
    );
    if (response.statusCode == 201) {
      return ListItem.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add item');
  }

  Future<ListItem> toggleItemChecked({
    required String listId,
    required String itemId,
    required bool isChecked,
    int? expectedVersion,
  }) async {
    final Map<String, dynamic> bodyData = {'is_checked': isChecked};
    if (expectedVersion != null) {
      bodyData['expected_version'] = expectedVersion;
    }
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/lists/$listId/items/$itemId'),
      headers: _headers,
      body: jsonEncode(bodyData),
    );
    if (response.statusCode == 200) {
      return ListItem.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 409) {
      throw const ConflictException();
    }
    throw Exception('Failed to update item status');
  }

  Future<ListItem> updateItemDetails({
    required String listId,
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
    String? note,
    bool? isChecked,
    int? expectedVersion,
  }) async {
    final Map<String, dynamic> bodyData = {};
    if (name != null) bodyData['name'] = name;
    if (quantity != null) bodyData['quantity'] = quantity;
    if (unit != null) bodyData['unit'] = unit;
    if (note != null) bodyData['note'] = note;
    if (isChecked != null) bodyData['is_checked'] = isChecked;
    if (expectedVersion != null) bodyData['expected_version'] = expectedVersion;

    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/lists/$listId/items/$itemId'),
      headers: _headers,
      body: jsonEncode(bodyData),
    );
    if (response.statusCode == 200) {
      return ListItem.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 409) {
      throw const ConflictException();
    }
    throw Exception('Failed to update item');
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/lists/$listId/items/$itemId'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }
}

class ConflictException implements Exception {
  final String message;
  const ConflictException([this.message = 'Item was updated by someone else.']);

  @override
  String toString() => message;
}
