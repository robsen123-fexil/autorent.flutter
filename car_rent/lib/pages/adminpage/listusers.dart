import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAndEmployeeListScreen extends StatefulWidget {
  const CustomerAndEmployeeListScreen({Key? key}) : super(key: key);

  @override
  _CustomerAndEmployeeListScreenState createState() =>
      _CustomerAndEmployeeListScreenState();
}

class _CustomerAndEmployeeListScreenState
    extends State<CustomerAndEmployeeListScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    List<Map<String, dynamic>> loadedUsers = [];

    final userSnapshots =
        await FirebaseFirestore.instance.collection('users').get();
    final employeeSnapshots =
        await FirebaseFirestore.instance.collection('employees').get();

    for (var doc in userSnapshots.docs) {
      final data = doc.data();
      data['docId'] = doc.id;
      data['collection'] = 'users';
      loadedUsers.add(data);
    }

    for (var doc in employeeSnapshots.docs) {
      final data = doc.data();
      data['docId'] = doc.id;
      data['collection'] = 'employees';
      loadedUsers.add(data);
    }

    setState(() {
      users = loadedUsers;
      filteredUsers = loadedUsers;
    });
  }

  void deleteUser(String docId, String collection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete User"),
            content: const Text("Are you sure you want to delete this user?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text("Yes"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .delete();
      fetchAllUsers(); // refresh the list
    }
  }

  void searchUser(String query) {
    final searchLower = query.toLowerCase();
    setState(() {
      filteredUsers =
          users.where((user) {
            final name = user['fullName']?.toLowerCase() ?? '';
            final email = user['email']?.toLowerCase() ?? '';
            return name.contains(searchLower) || email.contains(searchLower);
          }).toList();
    });
  }

  Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.blue[100]!;
      case 'employee':
        return Colors.green[100]!;
      case 'customer':
      default:
        return Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registered Users"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                onChanged: searchUser,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search users...",
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user['fullName'] ?? 'No name'),
                      // subtitle: Text(user['email'] ?? 'No email'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => deleteUser(user['docId'], user['collection']),
                      ),
                      isThreeLine: true,
                      contentPadding: const EdgeInsets.all(12),
                      tileColor: Colors.white,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      subtitleTextStyle: TextStyle(color: Colors.grey[700]),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: getRoleColor(user['role'] ?? ''),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user['role'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
