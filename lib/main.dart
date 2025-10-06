//all the imports used in the code
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
  //final values for the id number name height weight and sprit
  final int id;
  final String name;
  final int height;
  final int weight;
  final String? sprite;
  //the lines bellow make these lines of code required for the app to run
  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    this.sprite,
  });
  //this puts the values from the app into variables that I can interact with and use
  factory Pokemon.fromJson(Map<String, dynamic> j) => Pokemon(
    id: j['id'] as int,
    name: j['name'] as String,
    height: j['height'] as int,
    weight: j['weight'] as int,
    sprite: (j['sprites']?['front_default']) as String?,
  );
}

//runs the main code
void main() => runApp(const MyApp());

/// Root widget (needs to be stateful so we can track current album id)
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // API has albums 1 through 151
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
    // Fetch the very first pokemon at startup
    _futurePokemon = fetchPokemon(_currentId);
  }

  /// Helper to load any given id and update state
  void _loadId(int id) {
    setState(() {
      // Clamp ID within range
      _currentId = id;
      //set loading state to true
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

  //used to force a error in the code if the user wants to get a error message
  void _break() {
    //sets the id value to 9990 which is higher than the limit
    final prevId = 9990;
    //it then loads the id value
    _loadId(prevId);
  }

  //is the build that is run for the code
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //shows the name of the app
      title: 'Pokemon Prev/Next Demo',
      //here I create the theme I use for the app
      theme: ThemeData(
        //use the material from the api
        useMaterial3: true,
        //I set the color scheme to a red color to fit with a pokeball theme
        colorSchemeSeed: const Color.fromARGB(255, 250, 72, 72),
      ),
      //here I create the scaffold for the home of the app
      home: Scaffold(
        //Here I create the appbar and style it
        appBar: AppBar(
          //I give it the name pokemon api Demo
          title: const Text('Pokemon API Demo'),
          //I set the background color to red for a pokeball theme
          backgroundColor: Colors.red,
          //I then set the text color to white to go with the balck or white pokemon theme
          foregroundColor: Colors.white,
          //Here I put the actions that can be done in the action bar
          actions: [
            // Prev button in the AppBar
            IconButton(
              onPressed: _loading ? null : _prev,
              tooltip: 'Previous Pokemon',
              icon: const Icon(Icons.navigate_before),
            ),
            //sized box to add spacing
            const SizedBox(width: 3),
            //I added this button to give a reload option in the app bar
            IconButton(
              onPressed: _loading ? null : () => _loadId(_currentId),
              tooltip: 'Reload current Pokemon',
              icon: const Icon(Icons.refresh),
            ),
            //added a sizedbox here for spacing
            const SizedBox(width: 3),
            // Next button in the AppBar
            IconButton(
              onPressed: _loading ? null : _next,
              tooltip: 'Next Pokemon',
              icon: const Icon(Icons.navigate_next),
            ),
          ],
        ),
        //Here I created the body wrapped in a refresh indicator
        body: RefreshIndicator(
          //where I then put on refresh using async
          onRefresh: () async {
            //load the current pokemon id
            _loadId(_currentId);
            //then wait for the future pokemon call
            await _futurePokemon;
          },
          //Then using a chiled wrapped in a list view
          child: ListView(
            //I add the physics to make the page alwayscrollable so I can
            //do a pull down refresh using the card by treating it like a scrollbar
            physics: const AlwaysScrollableScrollPhysics(),
            //I then add a consitant padding for spacing reasons
            padding: EdgeInsets.all(16),
            //I then put shrinkwrap because it helped fits some erros where the
            //the images would break and page layout would go insane
            shrinkWrap: true,
            //THen I create a lists of children
            children: [
              //which a const sizedbox with a hieght of 20 to space the children from the top
              const SizedBox(height: 20),
              //I then use center to center everything
              Center(
                //I then make a call to the future builder with the pokemon class
                child: FutureBuilder<Pokemon>(
                  //with the furture called _future Pokemon
                  future: _futurePokemon,
                  //I then use a builder with the context and snapshot
                  builder: (context, snapshot) {
                    // While loading, show a spinner
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        _loading) {
                      //this shows the circular progress indicator when loading
                      return const CircularProgressIndicator();
                    }
                    // If there was an error, show it + Retry button
                    if (snapshot.hasError) {
                      //return padding
                      return Padding(
                        //create a consistent padding for the page
                        padding: const EdgeInsets.all(16),
                        //then create a child to display the card
                        child: Card(
                          //set the main background color to red to fit the pokeball theme
                          color: Colors.red,
                          //set the margins to match the padding but a little bigger to make the card
                          //larger
                          margin: const EdgeInsets.all(21),
                          //I then round the border to make the card unique and stand out
                          shape: RoundedRectangleBorder(
                            //The radius is then set to a nice 16 like the rounding to fix the edges
                            borderRadius: BorderRadius.circular(26),
                          ),
                          //I then wrapp everything in padding again
                          child: Padding(
                            //With a even padding of 16 around the icons
                            padding: EdgeInsets.all(16),
                            //I then put a column to have everything going stright down
                            child: Column(
                              //I then set them to the minimuin main axis size
                              mainAxisSize: MainAxisSize.min,
                              //I then create a list of children to hold the vlaues
                              children: [
                                //I then create a icon for a error value
                                const Icon(
                                  // here I set the icon to a error symbol
                                  Icons.error,
                                  //I then jack up the size to 142 to make it large and prominit
                                  size: 142,
                                  //I then make it white to fit with the red and white theme
                                  color: Colors.white,
                                ),
                                //I then add a sizedbox with a 19 size to put spacebetween the symbol and
                                //text
                                const SizedBox(height: 19),
                                //Here I print the error with the error message
                                Text(
                                  'Error: ${snapshot.error}',
                                  //I then center the text
                                  textAlign: TextAlign.center,
                                  //And style the text to fit the white text theme and have a decent size
                                  style: TextStyle(
                                    fontSize: 26,
                                    color: Colors.white,
                                  ),
                                ),
                                //I then put another sized box smaller than the one above bacause
                                //I want the buttons closer to the text
                                const SizedBox(height: 12),
                                //I then create a filledbutton to allow the user to reload the page
                                //to see if that fixs the page and removes the error
                                FilledButton.icon(
                                  onPressed: () => _loadId(_currentId),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                                //I then create a sized box to put some space between the buttons
                                const SizedBox(height: 9),
                                //I then create a filledbutton to allow the user to go pack to the first
                                //pokemon
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
                      //I set the color of the card to red like the error card
                      color: Colors.red,
                      //I then set the margin to be the same all around and the same as the padding
                      margin: const EdgeInsets.all(16),
                      //I then round the card to make it the same as the as the error card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      //I then use a child with padding
                      child: Padding(
                        //then use the padding to make the card bigger
                        padding: EdgeInsets.all(53),
                        //I then use a child column to hold the information in a column
                        child: Column(
                          //I then set everything to the min size of the main axis size
                          mainAxisSize: MainAxisSize.min,
                          //I then use a list of children
                          children: [
                            //then if we have a sprit
                            if (album.sprite != null)
                              //use the network image of the sprit with the given with and height
                              Image.network(
                                album.sprite!,
                                width: 200,
                                height: 200,
                              )
                            //if we dont have a sprit
                            else
                              //create a circle avater showing the pokemon id
                              CircleAvatar(child: Text('${album.id}')),
                            //then put a small sizedbox of 3 bellow the sprit
                            const SizedBox(height: 3),
                            //then using a text box
                            Text(
                              //print the name of the pokemon in full upper case
                              album.name.toUpperCase(),
                              //style the text to be bigger than the rest with a white color
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                              ),
                            ),
                            //used a small sized box with a height of 8 to put space
                            const SizedBox(height: 8),
                            //create a text box
                            Text(
                              //print the id followed by the id number and style it to match all other text
                              'id: ${album.id}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            //create a small sized box with a height of 8 to put space
                            const SizedBox(height: 8),
                            //create a text box
                            Text(
                              //print the pokemons height and style to match all other text
                              'Height: ${album.height}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            //create a small sized box with a heigh to of 8 to put space
                            const SizedBox(height: 8),
                            //create a text box
                            Text(
                              //print the weight of the pokemon and style it to match the rest of the text
                              'weight: ${album.weight}',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
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
          // FutureBuilder listens to our _futureAlbum
        ),
        // Bottom bar with both Prev and Next buttons
        bottomNavigationBar: Container(
          //margin is used to put the buttons above the bottom of the screen and make space
          margin: const EdgeInsets.only(bottom: 16),
          //then create a child sizedbox
          child: SizedBox(
            //set the height to 180 to make enough space to take up room
            height: 180,
            //then use a child padding
            child: Padding(
              //to put a small padding of 8 on all sides
              padding: const EdgeInsets.all(8),
              //then using a child column
              child: Column(
                //create the childen in a row and column to style the buttons
                //I did this because I think it looks nice and if I layed them
                //Out they gave a pixel overflow
                children: [
                  Row(
                    //I then set the mainaxis size to the min value
                    mainAxisSize: MainAxisSize.min,
                    //Then use a children list of filled buttons with icons
                    children: [
                      //THis one is used to go back a pokemon
                      FilledButton.icon(
                        onPressed: _loading ? null : _prev,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Prev'),
                      ),
                      //this sized box is used to split the prev and next apart and center them over the
                      //buttons bellow them
                      const SizedBox(width: 44),
                      //I use this button to go to the next pokemon
                      FilledButton.icon(
                        onPressed: _loading ? null : _next,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ],
                  ),
                  //this const sized box allows for space and room between the buttons
                  const SizedBox(height: 8),
                  //I then create a a new row to hold the bottom buttons
                  Row(
                    //set the main axis size to the min
                    mainAxisSize: MainAxisSize.min,
                    //then a group of children
                    children: [
                      //I use this button to reload the page
                      FilledButton.icon(
                        onPressed: _loading ? null : () => _loadId(_currentId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reload'),
                      ),
                      //this sizedbox puts space between the buttons
                      const SizedBox(width: 20),
                      //I use this button to force an error
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
