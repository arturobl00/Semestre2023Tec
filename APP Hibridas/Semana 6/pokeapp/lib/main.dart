import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PokemonScreen(),
    );
  }
}

class MyPokemon extends StatefulWidget {
  const MyPokemon({super.key});

  @override
  State<MyPokemon> createState() => _MyPokemonState();
}

class _MyPokemonState extends State<MyPokemon> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("Obtener"),
          onPressed: () {
            fetchPokemonData();
          },
        ),
      ),
    );
  }

  void fetchPokemonData() {
    var url = Uri.https("raw.githubusercontent.com",
        "/Biuni/PokemonGO-Pokedex/master/pokedex.json");
    http.get(url).then((value) {
      print(value.body);
    });
  }
}

class Pokemon {
  final String name;
  final String imageUrl;

  Pokemon({required this.name, required this.imageUrl});
}

class PokemonApi {
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  static Future<List<Pokemon>> fetchPokemons() async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon?limit=20'));
    if (response.statusCode == 200) {
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

class PokemonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon'),
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
