import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(PokemonApp());
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon API',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PokemonList(),
    );
  }
}

class PokemonList extends StatefulWidget {
  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<Map<String, dynamic>> _pokemonList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        List<Map<String, dynamic>> pokemonWithImages = [];

        for (var pokemon in results) {
          final detailsResponse = await http.get(Uri.parse(pokemon['url']));
          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            pokemonWithImages.add({
              'name': pokemon['name'],
              'image': detailsData['sprites']['front_default'],
            });
          }
        }

        setState(() {
          _pokemonList = pokemonWithImages;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar los Pokémon.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pokémon'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _pokemonList.length,
              itemBuilder: (context, index) {
                final pokemon = _pokemonList[index];
                return ListTile(
                  leading: pokemon['image'] != null
                      ? Image.network(pokemon['image'])
                      : Icon(Icons.image_not_supported),
                  title: Text(pokemon['name']),
                );
              },
            ),
    );
  }
}