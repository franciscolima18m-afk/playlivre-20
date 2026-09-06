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

  final List<MusicVideo> musicas = [
    MusicVideo(
      titulo: 'Música de demonstração',
      artista: 'PlayLivre',
      videoId: 'dQw4w9WgXcQ',
    ),
    MusicVideo(
      titulo: 'Vídeo musical 2',
      artista: 'YouTube Music',
      videoId: 'kJQP7kiw5Fk',
    ),
    MusicVideo(
      titulo: 'Vídeo musical 3',
      artista: 'PlayLivre',
      videoId: '9bZkp7q19f0',
    ),
  ];

  int musicaAtual = 0;

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
        privacyEnhancedMode: true,
        mute: false,
      ),
    );
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

  @override
  void dispose() {
    controller.close();
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
        centerTitle: false,
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
                    controller.play();
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

            const Text(
              'Músicas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...List.generate(
              musicas.length,
              (index) {
                final item = musicas[index];

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
                    title: Text(item.titulo),
                    subtitle: Text(item.artista),
                    trailing: Icon(
                      musicaAtual == index
                          ? Icons.equalizer
                          : Icons.play_arrow,
                      color: Colors.red,
                    ),
                    onTap: () {
                      tocarMusica(index);
                    },
                  ),
                );
              },
            ),

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
