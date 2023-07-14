import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../helpers/Helpers.dart';

class SettingsPage extends StatefulWidget {
  late final String email;
  SettingsPage({required this.email});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}



class _SettingsPageState extends State<SettingsPage> {

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late TextEditingController _emailController= TextEditingController();

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmation'),
            content: Text('Do you want to delete this user?'),
            actions: [
              TextButton(
                  onPressed: () async {
                    try {
                      final QuerySnapshot snapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: widget.email)
                          .limit(1)
                          .get();

                      if (snapshot.docs.isNotEmpty) {
                        final DocumentSnapshot userDoc = snapshot.docs.first;
                        await userDoc.reference.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User deleted successfully!")),
                        );
                      }

                      Navigator.pop(context, true);

                      /*final CollectionReference collections = FirebaseFirestore.instance.collection('users') ;
                      collections.doc(widget.id).delete();*/
                      /* Navigator.pop(context,true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully!")));
*/
                    } catch (e) {
                      print("Error deleting the user: $e");
                    }
                    if(context != null && Navigator.of(context).canPop()){
                      Navigator.pop(context,true);
                    }
                  },
                  style: TextButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  )),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: _getItemIcon(index),
            title: Text(_getItemTitle(index)),
            onTap: () {
              _handleItemClick(context, index);
            },
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return Divider();
        },
        itemCount: _getItemCount(),
      ),
    );
  }

  int _getItemCount() {
    return 3; // Total number of items in the list
  }

  String _getItemTitle(int index) {
    switch (index) {
      case 0:
        return 'Edit Email';
      case 1:
        return 'Delete Account';
      case 2:
        return 'Logout';
      default:
        return '';
    }
  }

  Icon _getItemIcon(int index) {
    switch (index) {
      case 0:
        return Icon(Icons.email);
      case 1:
        return Icon(Icons.delete);
      case 2:
        return Icon(Icons.logout);
      default:
        return Icon(Icons.error);
    }
  }

  void _handleItemClick(BuildContext context, int index) {
    switch (index) {
      case 0:
        _showEditConfirmationDialog(context);
        break;
      case 1:
        _showDeleteAccountConfirmationDialog(context);
        break;
      case 2:
        _logout(context);
        break;
    }
  }

  void _showEditConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String currentEmail = _emailController.text.trim().toLowerCase();
        late TextEditingController _newEmailController;
        _newEmailController = TextEditingController(text: currentEmail);



        return AlertDialog(
          title: const Text("Edit user"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Current Email'),
                  validator: (String? value) {
                    if (value!.trim().isEmpty) {
                      return 'The current email is required!';
                    } else if (!isValidEmail(value)) {
                      return "Invalid email";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _newEmailController,
                  decoration: const InputDecoration(labelText: 'New Email'),
                  validator: (String? value) {
                    if (value!.trim().isEmpty) {
                      return 'The new email is required!';
                    } else if (!isValidEmail(value)) {
                      return "Invalid email";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _loading = true;
                  });

                  try {
                    QuerySnapshot snapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('email', isEqualTo: _emailController.text)
                        .limit(1)
                        .get();
                    print("Utilizador!");
                    print(_emailController.text);
                    print(_newEmailController.text);
                    print(snapshot.docs.first);

                    if (snapshot.docs.isNotEmpty) {
                      // Atualizar o e-mail no Firestore
                      DocumentSnapshot userDoc = snapshot.docs.first;
                      await userDoc.reference.update({
                        'email': _newEmailController.text,
                      });

                      // Atualizar o e-mail na autenticação do Firebase
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await user.updateEmail(_newEmailController.text);
                      }

                      setState(() {
                        _loading = false;
                        widget.email = _newEmailController.text;
                      });

                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context, true);
                      }

                      Fluttertoast.showToast(
                        msg: "E-mail updated successfully.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: "User not found with the current email.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }

                  } catch (error) {
                    setState(() {
                      _loading = false;
                    });
                  }
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (Route<dynamic> route) => false);
                }
              },
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Edit',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account?'),
          actions: [
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
              child: Text('Delete'),
              onPressed: () {
                // Implement the account deletion logic here
                // ...
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) {
    // Redirect to the home page
    Navigator.pushNamedAndRemoveUntil(
        context, '/', (Route<dynamic> route) => false);
  }
}
