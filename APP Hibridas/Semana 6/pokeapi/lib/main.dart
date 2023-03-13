import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AppPokemon());
}

class AppPokemon extends StatelessWidget {
  const AppPokemon({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyPokemon(),
    );
  }
}

class MyPokemon extends StatelessWidget {
  const MyPokemon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon'),
      ),
      body: FutureBuilder<List<Pokemon>>(
        future: PokemonApi.fetchPokemons(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final pokemons = snapshot.data!;
            return ListView.builder(
              itemCount: pokemons.length,
              itemBuilder: (context, index) {
                final pokemon = pokemons[index];
                return Container(
                  margin: const EdgeInsets.only(
                    left: 20.0,
                    top: 10.0,
                    bottom: 50.0,
                  ),
                  width: 30.0,
                  child: Column(
                    children: [
                      Container(
                        height: 300,
                        width: 200,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/images.png"),
                                fit: BoxFit.cover)),
                        child: Image.network(
                          pokemon.imageUrl,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            )),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Text("Nombre: ${pokemon.name}"),
                                Text("Tipo: ${pokemon.type}"),
                              ],
                            ),
                            Column(
                              children: [
                                Text("Habilidad: ${pokemon.abilities}"),
                                Text("Movimiento: ${pokemon.moves}"),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );

                /*ListTile(
                  leading: Image.network(pokemon.imageUrl),
                  title: Text(pokemon.name),
                  //subtitle: Text(pokemon.abilities),
                );*/
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}

class Pokemon {
  final String name;
  final String imageUrl;
  final String abilities;
  final String moves;
  final String type;

  Pokemon({
    required this.name,
    required this.imageUrl,
    required this.abilities,
    required this.moves,
    required this.type,
  });
}

class PokemonApi {
  //Declarar una constante con url del api
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  //Declarar la lista de elementos que tiene el api
  static Future<List<Pokemon>> fetchPokemons() async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon?limit=3'));
    if (response.statusCode == 200) {
      print(response.body);
      final decodedBody = jsonDecode(response.body);
      final pokemons = <Pokemon>[];
      for (final pokemon in decodedBody['results']) {
        final pokemonResponse = await http.get(Uri.parse(pokemon['url']));
        if (pokemonResponse.statusCode == 200) {
          final pokemonDecodedBody = jsonDecode(pokemonResponse.body);
          final pokemon = Pokemon(
            name: pokemonDecodedBody['name'],
            imageUrl: pokemonDecodedBody['sprites']['front_default'],
            abilities: pokemonDecodedBody['abilities'][0]['ability']['name'],
            moves: pokemonDecodedBody['moves'][0]['move']['name'],
            type: pokemonDecodedBody['types'][0]['type']['name'],
          );
          pokemons.add(pokemon);
        }
      }
      return pokemons;
    } else {
      throw Exception('Failed to fetch pokemons');
    }
  }
}


/*Text("Nombre: ${pokemon.name}"),
 Text("Abilidad: ${pokemon.abilities}"),
 Text("Movimiento: ${pokemon.moves}"),
 Text("Tipo: ${pokemon.type}"),
 Image.network(pokemon.imageUrl)*/