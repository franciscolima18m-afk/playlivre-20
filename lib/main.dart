import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const PlayLivreApp());
}

class Song {
  final String title;
  final String artist;
  final String url;
  final String image;

  const Song({
    required this.title,
    required this.artist,
    required this.url,
    required this.image,
  });
}

const List<Song> songs = [
  Song(
    title: 'Horizonte Digital',
    artist: 'PlayLivre Demo',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    image: 'https://picsum.photos/300/300?random=1',
  ),
  Song(
    title: 'Cidade Neon',
    artist: 'Future Sounds',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    image: 'https://picsum.photos/300/300?random=2',
  ),
  Song(
    title: 'Modo DJ',
    artist: 'Demo Artist',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    image: 'https://picsum.photos/300/300?random=3',
  ),
  Song(
    title: 'Noite Livre',
    artist: 'PlayLivre Demo',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    image: 'https://picsum.photos/300/300?random=4',
  ),
];

class PlayLivreApp extends StatelessWidget {
  const PlayLivreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayLivre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0D12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const PlayLivreHome(),
    );
  }
}

class PlayLivreHome extends StatefulWidget {
  const PlayLivreHome({super.key});

  @override
  State<PlayLivreHome> createState() => _PlayLivreHomeState();
}

class _PlayLivreHomeState extends State<PlayLivreHome> {
  final AudioPlayer player = AudioPlayer();
  final TextEditingController searchController = TextEditingController();

  int currentIndex = 0;

  bool shuffle = false;
  bool repeat = false;
  bool isSearching = false;

  final Set<int> favorites = {};

  @override
  void initState() {
    super.initState();

    _loadSong(0);

    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _next();
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadSong(int index) async {
    if (index < 0 || index >= songs.length) return;

    setState(() {
      currentIndex = index;
    });

    try {
      await player.setUrl(songs[currentIndex].url);
    } catch (e) {
      debugPrint('Erro ao carregar áudio: $e');
    }
  }

  Future<void> _playSong(int index) async {
    await _loadSong(index);
    await player.play();
  }

  Future<void> _next() async {
    int nextIndex;

    if (shuffle) {
      if (songs.length <= 1) {
        nextIndex = currentIndex;
      } else {
        do {
          nextIndex = Random().nextInt(songs.length);
        } while (nextIndex == currentIndex);
      }
    } else {
      nextIndex = currentIndex + 1;

      if (nextIndex >= songs.length) {
        if (repeat) {
          nextIndex = 0;
        } else {
          nextIndex = 0;
        }
      }
    }

    await _playSong(nextIndex);
  }

  Future<void> _previous() async {
    if (player.position.inSeconds > 5) {
      await player.seek(Duration.zero);
      return;
    }

    int previousIndex = currentIndex - 1;

    if (previousIndex < 0) {
      previousIndex = songs.length - 1;
    }

    await _playSong(previousIndex);
  }

  Future<void> _togglePlay() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (favorites.contains(index)) {
        favorites.remove(index);
      } else {
        favorites.add(index);
      }
    });
  }

  List<int> get filteredSongs {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      return List.generate(songs.length, (index) => index);
    }

    return List.generate(songs.length, (index) => index)
        .where((index) {
      final song = songs[index];

      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    player.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = songs[currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar música...',
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              )
            : const Text(
                'PlayLivre',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
            ),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;

                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
              children: [
                _buildWelcome(),
                const SizedBox(height: 24),

                const Text(
                  'Suas músicas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...filteredSongs.map(
                  (index) => _buildSongTile(index),
                ),

                const SizedBox(height: 24),

                if (favorites.isNotEmpty) ...[
                  const Text(
                    'Favoritos ❤️',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...favorites.map(
                    (index) => _buildSongTile(index),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),

      bottomSheet: _buildPlayer(song),
    );
  }

  Widget _buildWelcome() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C4DFF),
            Color(0xFF512DA8),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.music_note,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'Sua música, do seu jeito.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ouça suas músicas favoritas no PlayLivre.',
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(int index) {
    final song = songs[index];
    final isCurrent = currentIndex == index;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: isCurrent,

        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            song.image,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 52,
                height: 52,
                color: Colors.deepPurple,
                child: const Icon(Icons.music_note),
              );
            },
          ),
        ),

        title: Text(
          song.title,
          style: TextStyle(
            fontWeight:
                isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),

        subtitle: Text(song.artist),

        trailing: IconButton(
          icon: Icon(
            favorites.contains(index)
                ? Icons.favorite
                : Icons.favorite_border,
            color: favorites.contains(index)
                ? Colors.red
                : null,
          ),
          onPressed: () {
            _toggleFavorite(index);
          },
        ),

        onTap: () {
          _playSong(index);
        },
      ),
    );
  }

  Widget _buildPlayer(Song song) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151821),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.4),
          ),
        ],
      ),

      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),

      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song.image,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 58,
                        height: 58,
                        color: Colors.deepPurple,
                        child: const Icon(Icons.music_note),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: Icon(
                    favorites.contains(currentIndex)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: favorites.contains(currentIndex)
                        ? Colors.red
                        : null,
                  ),
                  onPressed: () {
                    _toggleFavorite(currentIndex);
                  },
                ),
              ],
            ),

            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = player.duration ?? Duration.zero;

                final max =
                    duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0;

                final value =
                    position.inMilliseconds
                        .clamp(
                          0,
                          duration.inMilliseconds,
                        )
                        .toDouble();

                return Column(
                  children: [
                    Slider(
                      value: value,
                      max: max,
                      onChanged: (newValue) {
                        player.seek(
                          Duration(
                            milliseconds:
                                newValue.toInt(),
                          ),
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: shuffle
                        ? Colors.deepPurpleAccent
                        : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      shuffle = !shuffle;
                    });
                  },
                ),

                IconButton(
                  icon: const Icon(
                    Icons.skip_previous,
                    size: 34,
                  ),
                  onPressed: _previous,
                ),

                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7C4DFF),
                  ),
                  child: IconButton(
                    iconSize: 38,
                    icon: Icon(
                      player.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: _togglePlay,
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    size: 34,
                  ),
                  onPressed: _next,
                ),

                IconButton(
                  icon: Icon(
                    repeat
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: repeat
                        ? Colors.deepPurpleAccent
                        : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      repeat = !repeat;
                      player.setLoopMode(
                        repeat
                            ? LoopMode.one
                            : LoopMode.off,
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int value) =>
        value.toString().padLeft(2, '0');

    final minutes =
        twoDigits(duration.inMinutes.remainder(60));

    final seconds =
        twoDigits(duration.inSeconds.remainder(60));

    return '$minutes:$seconds';
  }
}
