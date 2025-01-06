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
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ),
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
  List<Map<String, dynamic>> _filteredPokemonList = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();
  TextEditingController _ipSearchController = TextEditingController();
  String _ipInfo = '';

  @override
  void initState() {
    super.initState();
    fetchPokemon();
    _searchController.addListener(_filterPokemons);
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
              'id': detailsData['id'],
              'height': detailsData['height'],
              'weight': detailsData['weight'],
              'abilities': detailsData['abilities']
                  .map((ability) => ability['ability']['name'])
                  .toList(),
            });
          }
        }

        setState(() {
          _pokemonList = pokemonWithImages;
          _filteredPokemonList = pokemonWithImages;
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

  void _filterPokemons() {
    setState(() {
      _filteredPokemonList = _pokemonList
          .where((pokemon) => pokemon['name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _fetchIpInfo() async {
    final ip = _ipSearchController.text;
    final apiKey = '5bfa51c315854c6f8e968cc048c7fb6b'; // Reemplaza con tu API Key de ipstack
    final url = Uri.parse('http://api.ipstack.com/$ip?access_key=$apiKey');

    setState(() {
      _ipInfo = 'Cargando...';
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ipInfo = '''
IP: ${data['ip']}
Tipo: ${data['type']}
Código del continente: ${data['continent_code']}
Nombre del continente: ${data['continent_name']}
Código del país: ${data['country_code']}
Nombre del país: ${data['country_name']}
Código de la región: ${data['region_code']}
Nombre de la región: ${data['region_name']}
Ciudad: ${data['city']}
Código postal: ${data['zip']}
''';
        });
      } else {
        setState(() {
          _ipInfo = 'No se pudo obtener información para esta IP.';
        });
      }
    } catch (e) {
      setState(() {
        _ipInfo = 'Error al obtener la información de la IP.';
      });
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ipSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pokédex',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple[100]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Barra de búsqueda para IP
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ipSearchController,
                            decoration: InputDecoration(
                              hintText: 'Ingresa la IP...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _fetchIpInfo,
                          child: Text('Buscar'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ],
                    ),
                    if (_ipInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _ipInfo,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Barra de búsqueda para Pokémon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar Pokémon...',
                  prefixIcon: Icon(Icons.catching_pokemon),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // Lista de Pokémon
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredPokemonList.length,
                      itemBuilder: (context, index) {
                        final pokemon = _filteredPokemonList[index];
                        return Card(
                          child: InkWell(
                            onTap: () => _showPokemonDetails(context, pokemon),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: 'pokemon-${pokemon['id']}',
                                  child: pokemon['image'] != null
                                      ? Image.network(
                                          pokemon['image'],
                                          height: 100,
                                        )
                                      : Icon(Icons.image_not_supported, size: 100),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  pokemon['name'].toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '#${pokemon['id'].toString().padLeft(3, '0')}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
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

  void _showPokemonDetails(BuildContext context, Map<String, dynamic> pokemon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'pokemon-${pokemon['id']}',
                  child: pokemon['image'] != null
                      ? Image.network(pokemon['image'], height: 150)
                      : Icon(Icons.image_not_supported, size: 150),
                ),
                SizedBox(height: 16),
                Text(
                  pokemon['name'].toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '#${pokemon['id'].toString().padLeft(3, '0')}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Altura', '${pokemon['height']} dm'),
                    _buildStatColumn('Peso', '${pokemon['weight']} hg'),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Habilidades',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: (pokemon['abilities'] as List)
                      .map((ability) => Chip(
                            label: Text(ability),
                            backgroundColor: Colors.deepPurple[100],
                          ))
                      .toList(),
                ),
                SizedBox(height: 16),
                TextButton(
                  child: Text('Cerrar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
