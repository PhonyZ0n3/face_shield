import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../helpers/Helpers.dart';
class UserDetailPage extends StatefulWidget {
  final String id;
  late final String email;
  late final List<double> faceData;


  UserDetailPage(
      {super.key,
      required this.id,
      required this.email,
      required this.faceData});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late TextEditingController _emailController;
  late TextEditingController _faceDataController;
  @override
  void initState(){
    String faceDataString = widget.faceData[0].toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'),'');
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _faceDataController=TextEditingController(text: faceDataString);
  }


  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text('Do you want to delete this user?'),
            actions: [
              TextButton(
                  onPressed: () async {
                    try {
                      final CollectionReference collections =
                          FirebaseFirestore.instance.collection('users');
                      collections.doc(widget.id).delete();
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Utilizador eliminado com sucesso!")));
                    } catch (e) {
                      print("Erro ao eliminar utilizador: $e");
                    }
                    if (context != null && Navigator.of(context).canPop()) {
                      Navigator.pop(context, true);
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

  void _showEditConfirmationDialog(BuildContext context) {

    String faceDataText=widget.faceData.toString().replaceAll('[', '').replaceAll(']', '');
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Edit user"),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (String? value) {
                      if (value!.trim().isEmpty) {
                        return 'O email é obrigatório!';
                      } else if (!isValidEmail(value)) {
                        return "Formato de email incorreto";
                      }
                      return null;
                    },
                    onChanged: (String value) {
                      setState(() {
                        _formKey.currentState!.validate();
                      });
                    },
                  ),
                  TextFormField(
                    controller: _faceDataController,
                    decoration: const InputDecoration(labelText: 'Face Data'),
                    validator: (String? value) {
                      if (value!.trim().isEmpty) {
                        return 'O Face Data é obrigatório!';
                      } else if (int.parse(value.trim()) == 0) {
                        return 'O Face Data tem de ser maior que 0!';
                      }
                    },
                    onChanged: (String value) {
                      setState(() {
                        _formKey.currentState!.validate();
                      });
                    },
                  )
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

                       List<double> faceDataList = [double.parse(_faceDataController.text)];
                      //atualizar os dados no firebaseStore
                     FirebaseFirestore.instance.collection('users').doc(widget.id).update(
                         {
                           'email': _emailController.text, 'faceData' : faceDataList,
                         }).then((value) {
                           print("Dados do utilizador atualizados com sucesso!");
                           setState(() {
                             _loading=false;
                             widget.email=_emailController.text;
                             //widget.faceData=_faceDataController.text.toString() as List<double>;
                           });
                           Navigator.of(context).pop();
                     }).catchError((error){
                       print("Erro ao atualizar os dados do utilizador $error");
                       setState(() {
                         _loading=false;
                       });
                     });


                      if (context != null && Navigator.of(context).canPop()) {
                        Navigator.pop(context, true);
                      }
                    }
                  },
                  style: TextButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Edit',
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
          title: const Text("User Detail"),
        ),
        body: SizedBox(
          width: double.infinity,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:!_loading ? Column(
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                  Text(
                    _emailController.text,
                    style: const TextStyle(fontSize: 25),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'FaceData',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                  Text(
                    _faceDataController.text,
                    style: const TextStyle(fontSize: 25),
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showEditConfirmationDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 38)),
                          child: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 25),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 26,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showDeleteConfirmationDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 30),
                              backgroundColor: Colors.red),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ): const Center(child: CircularProgressIndicator()),
            ),
          ),
        ));
  }
}