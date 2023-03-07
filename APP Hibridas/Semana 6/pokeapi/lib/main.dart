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
                return ListTile(
                  leading: Image.network(pokemon.imageUrl),
                  title: Text(pokemon.name),
                );
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

  Pokemon({required this.name, required this.imageUrl});
}

class PokemonApi {
  //Declarar una constante con url del api
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  //Declarar la lista de elementos que tiene el api
  static Future<List<Pokemon>> fetchPokemons() async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon?limit=151'));
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
