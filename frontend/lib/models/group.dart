import 'user.dart';

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final User? user;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    this.user,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'MEMBER',
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String createdBy;
  final int memberCount;
  final int listCount;
  final List<GroupMember> members;

  Group({
    required this.id,
    required this.name,
    required this.createdBy,
    this.memberCount = 1,
    this.listCount = 0,
    this.members = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List<dynamic>? ?? [];
    List<GroupMember> parsedMembers = rawMembers
        .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
        .toList();

    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      memberCount: json['member_count'] as int? ?? parsedMembers.length,
      listCount: json['list_count'] as int? ?? 0,
      members: parsedMembers,
    );
  }
}
