import 'package:cloud_firestore/cloud_firestore.dart';
//Conectar a la base de datos
FirebaseFirestore db = FirebaseFirestore.instance;

//Crear una lista sobre los datos registrados
Future<List> getPeople() async {
  //Crear la lista
  List people = [];
  //Seleccionar la base de datos o colleccion
  CollectionReference collectionReference = db.collection('people');

  //Ejecutar el query
  QuerySnapshot queryPeople = await collectionReference.get();

  //Recorrer el query y agregar los resultados a la lista
  for (var documento in queryPeople.docs) {
    people.add(documento.data());
  }

  return people;
}
