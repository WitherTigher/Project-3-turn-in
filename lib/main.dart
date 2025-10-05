import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Fetch one Album by ID from jsonplaceholder
Future<Pokemon> fetchPokemon(int id) async {
  // Build the request URL like: https://jsonplaceholder.typicode.com/albums/5
  final uri = Uri.parse('https://pokeapi.co/api/v2/pokemon/$id');

  // Perform GET request with a 10-second timeout
  final res = await http.get(uri).timeout(const Duration(seconds: 10));

  if (res.statusCode == 200) {
    // Parse the JSON body into a Dart map, then into an Album object
    return Pokemon.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  } else {
    // If server response wasn’t 200, throw an exception
    throw Exception('Failed to load pokemon (HTTP ${res.statusCode})');
  }
}

/// Simple Dart model for an Album record
class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final String? sprite;

  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    this.sprite,
  });

  factory Pokemon.fromJson(Map<String, dynamic> j) => Pokemon(
    id: j['id'] as int,
    name: j['name'] as String,
    height: j['height'] as int,
    weight: j['weight'] as int,
    sprite: (j['sprites']?['front_default']) as String?,
  );
}

void main() => runApp(const MyApp());

/// Root widget (needs to be stateful so we can track current album id)
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // API has albums 1 through 100
  static const int minId = 1;
  static const int maxId = 151;

  // Track the current album id
  int _currentId = minId;

  // Hold the current fetch operation
  late Future<Pokemon> _futurePokemon;

  // Track whether we are in the middle of a fetch
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Fetch the very first album at startup
    _futurePokemon = fetchPokemon(_currentId);
  }

  /// Helper to load any given id and update state
  void _loadId(int id) {
    setState(() {
      // Clamp ID within range
      _currentId = id;
      _loading = true;

      // Start fetching. whenComplete runs after success OR error.
      _futurePokemon = fetchPokemon(_currentId).whenComplete(() {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      });
    });
  }

  /// Go forward to the next album (wrap at max → min)
  void _next() {
    final nextId = (_currentId + 1) > maxId ? minId : _currentId + 1;
    _loadId(nextId);
  }

  /// Go backward to the previous album (wrap at min → max)
  void _prev() {
    final prevId = (_currentId - 1) < minId ? maxId : _currentId - 1;
    _loadId(prevId);
  }

  void _break() {
    final prevId = 9990;
    _loadId(prevId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon Prev/Next Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 250, 72, 72),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pokemon API Demo'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          actions: [
            // Prev button in the AppBar
            IconButton(
              onPressed: _loading ? null : _prev,
              tooltip: 'Previous Pokemon',
              icon: const Icon(Icons.navigate_before),
            ),
            const SizedBox(width: 3),
            IconButton(
              onPressed: _loading ? null : () => _loadId(_currentId),
              tooltip: 'Reload current Pokemon',
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 3),
            // Next button in the AppBar
            IconButton(
              onPressed: _loading ? null : _next,
              tooltip: 'Next Pokemon',
              icon: const Icon(Icons.navigate_next),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _loadId(_currentId);
            await _futurePokemon;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            shrinkWrap: true,
            children: [
              const SizedBox(height: 20),
              Center(
                child: FutureBuilder<Pokemon>(
                  future: _futurePokemon,
                  builder: (context, snapshot) {
                    // While loading, show a spinner
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        _loading) {
                      return const CircularProgressIndicator();
                    }
                    // If there was an error, show it + Retry button
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: Colors.red,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error,
                                  size: 142,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 19),
                                Text(
                                  'Error: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () => _loadId(_currentId),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                                const SizedBox(height: 9),
                                FilledButton.icon(
                                  onPressed: () => _loadId(minId),
                                  icon: const Icon(Icons.home),
                                  label: const Text('Go Back to the start'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    // Success: render album data inside a Card
                    final album = snapshot.data!;
                    return Card(
                      color: Colors.red,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (album.sprite != null)
                              Image.network(
                                album.sprite!,
                                width: 200,
                                height: 200,
                              )
                            else
                              CircleAvatar(child: Text('${album.id}')),
                            const SizedBox(height: 0),
                            Text(
                              album.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'id: ${album.id}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Height: ${album.height}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'weight: ${album.weight}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                FilledButton(
                                  onPressed: _loading ? null : _prev,
                                  child: const Text('Back'),
                                ),
                                const SizedBox(width: 20),
                                FilledButton(
                                  onPressed: _loading ? null : _next,
                                  child: const Text('Next'),
                                ),
                              ],
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
          // FutureBuilder listens to our _futureAlbum
        ),
        // Bottom bar with both Prev and Next buttons
        bottomNavigationBar: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : _prev,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Prev'),
                      ),
                      const SizedBox(width: 44),
                      FilledButton.icon(
                        onPressed: _loading ? null : _next,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : () => _loadId(_currentId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reload'),
                      ),
                      const SizedBox(width: 20),
                      FilledButton.icon(
                        onPressed: _loading ? null : _break,
                        icon: const Icon(Icons.error),
                        label: const Text('Force Error'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
