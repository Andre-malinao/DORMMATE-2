import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final userBox = Hive.box('userBox');
    final currentUser = Map<String, dynamic>.from(
      userBox.get('currentUser') as Map,
    );
    _usernameController = TextEditingController(text: currentUser['username']);
    _emailController = TextEditingController(text: currentUser['email']);
  }

  Map<String, dynamic>? getCurrentUser() {
    final userBox = Hive.box('userBox');
    final data = userBox.get('currentUser');
    if (data != null) {
      return Map<String, dynamic>.from(data as Map);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, size: 50, color: Colors.blue),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final userBox = Hive.box('userBox');
                    final updatedUser = {
                      'username': _usernameController.text,
                      'email': _emailController.text,
                    };
                    userBox.put('currentUser', updatedUser);
                    // Return the updated data to the profile screen
                    Navigator.pop(context, updatedUser);
                  }
                },
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
