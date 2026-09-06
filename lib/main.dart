import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  runApp(const PlayLivreApp());
}

class PlayLivreApp extends StatelessWidget {
  const PlayLivreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlayLivre',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff090909),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PlayerPage(),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final YoutubePlayerController controller;

  final TextEditingController pesquisaController =
      TextEditingController();

  final List<MusicVideo> musicas = [
    MusicVideo(
      titulo: 'Música de demonstração',
      artista: 'PlayLivre',
      videoId: 'dQw4w9WgXcQ',
    ),
    MusicVideo(
      titulo: 'Despacito',
      artista: 'Luis Fonsi',
      videoId: 'kJQP7kiw5Fk',
    ),
    MusicVideo(
      titulo: 'Gangnam Style',
      artista: 'PSY',
      videoId: '9bZkp7q19f0',
    ),
    MusicVideo(
      titulo: 'Shape of You',
      artista: 'Ed Sheeran',
      videoId: 'JGwWngGsE7g',
    ),
    MusicVideo(
      titulo: 'Believer',
      artista: 'Imagine Dragons',
      videoId: '7wtfhZwyrcc',
    ),
    MusicVideo(
      titulo: 'Counting Stars',
      artista: 'OneRepublic',
      videoId: 'hT_nvWreIhg',
    ),
    MusicVideo(
      titulo: 'Uptown Funk',
      artista: 'Mark Ronson',
      videoId: 'OPf0YbXqDm0',
    ),
    MusicVideo(
      titulo: 'Faded',
      artista: 'Alan Walker',
      videoId: '60ItHLz5WEA',
    ),
    MusicVideo(
      titulo: 'Numb',
      artista: 'Linkin Park',
      videoId: 'kXYiU_JCYtU',
    ),
    MusicVideo(
      titulo: 'Bohemian Rhapsody',
      artista: 'Queen',
      videoId: 'fJ9rUzIMcZQ',
    ),
  ];

  final Set<String> favoritos = {};

  int musicaAtual = 0;
  String pesquisa = '';

  @override
  void initState() {
    super.initState();

    controller = YoutubePlayerController.fromVideoId(
      videoId: musicas[musicaAtual].videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        showVideoAnnotations: false,
        strictRelatedVideos: true,
        mute: false,
      ),
    );
  }

  List<MusicVideo> get musicasFiltradas {
    if (pesquisa.trim().isEmpty) {
      return musicas;
    }

    final termo = pesquisa.toLowerCase();

    return musicas.where((musica) {
      return musica.titulo.toLowerCase().contains(termo) ||
          musica.artista.toLowerCase().contains(termo);
    }).toList();
  }

  void tocarMusica(int indice) {
    setState(() {
      musicaAtual = indice;
    });

    controller.loadVideoById(
      videoId: musicas[indice].videoId,
    );
  }

  void proximaMusica() {
    int proxima = musicaAtual + 1;

    if (proxima >= musicas.length) {
      proxima = 0;
    }

    tocarMusica(proxima);
  }

  void musicaAnterior() {
    int anterior = musicaAtual - 1;

    if (anterior < 0) {
      anterior = musicas.length - 1;
    }

    tocarMusica(anterior);
  }

  void alternarFavorito(MusicVideo musica) {
    setState(() {
      if (favoritos.contains(musica.videoId)) {
        favoritos.remove(musica.videoId);
      } else {
        favoritos.add(musica.videoId);
      }
    });
  }

  @override
  void dispose() {
    controller.close();
    pesquisaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musica = musicas[musicaAtual];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff090909),
        title: const Text(
          'PlayLivre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Agora tocando',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: YoutubePlayer(
                controller: controller,
                aspectRatio: 16 / 9,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              musica.titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              musica.artista,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white60,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 34,
                  onPressed: musicaAnterior,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 18),
                IconButton(
                  iconSize: 42,
                  onPressed: () {
                    controller.playVideo();
                  },
                  icon: const Icon(Icons.play_circle_fill),
                ),
                const SizedBox(width: 18),
                IconButton(
                  iconSize: 34,
                  onPressed: proximaMusica,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // BARRA DE PESQUISA
            TextField(
              controller: pesquisaController,
              onChanged: (valor) {
                setState(() {
                  pesquisa = valor;
                });
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar músicas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: pesquisa.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          pesquisaController.clear();
                          setState(() {
                            pesquisa = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xff181818),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Músicas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${musicasFiltradas.length} músicas',
                  style: const TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (musicasFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 50,
                      color: Colors.white38,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhuma música encontrada',
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

            ...musicasFiltradas.map((item) {
              final indice = musicas.indexOf(item);
              final estaTocando = musicaAtual == indice;
              final favorito = favoritos.contains(item.videoId);

              return Card(
                color: const Color(0xff181818),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    item.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(item.artista),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          favorito
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: favorito
                              ? Colors.red
                              : Colors.white54,
                        ),
                        onPressed: () {
                          alternarFavorito(item);
                        },
                      ),
                      Icon(
                        estaTocando
                            ? Icons.equalizer
                            : Icons.play_arrow,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  onTap: () {
                    tocarMusica(indice);
                  },
                ),
              );
            }),

            const SizedBox(height: 20),

            const Text(
              'Toque no vídeo para iniciar o áudio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MusicVideo {
  final String titulo;
  final String artista;
  final String videoId;

  const MusicVideo({
    required this.titulo,
    required this.artista,
    required this.videoId,
  });
}
