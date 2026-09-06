import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    const MusicVideo(
      titulo: 'Música de demonstração',
      artista: 'PlayLivre',
      videoId: 'dQw4w9WgXcQ',
    ),
    const MusicVideo(
      titulo: 'Despacito',
      artista: 'Luis Fonsi',
      videoId: 'kJQP7kiw5Fk',
    ),
    const MusicVideo(
      titulo: 'Gangnam Style',
      artista: 'PSY',
      videoId: '9bZkp7q19f0',
    ),
    const MusicVideo(
      titulo: 'Shape of You',
      artista: 'Ed Sheeran',
      videoId: 'JGwWngGsE7g',
    ),
    const MusicVideo(
      titulo: 'Believer',
      artista: 'Imagine Dragons',
      videoId: '7wtfhZwyrcc',
    ),
    const MusicVideo(
      titulo: 'Counting Stars',
      artista: 'OneRepublic',
      videoId: 'hT_nvWreIhg',
    ),
    const MusicVideo(
      titulo: 'Uptown Funk',
      artista: 'Mark Ronson',
      videoId: 'OPf0YbXqDm0',
    ),
    const MusicVideo(
      titulo: 'Faded',
      artista: 'Alan Walker',
      videoId: '60ItHLz5WEA',
    ),
    const MusicVideo(
      titulo: 'Numb',
      artista: 'Linkin Park',
      videoId: 'kXYiU_JCYtU',
    ),
    const MusicVideo(
      titulo: 'Bohemian Rhapsody',
      artista: 'Queen',
      videoId: 'fJ9rUzIMcZQ',
    ),
  ];

  final Set<String> favoritos = {};
  final Map<String, List<String>> playlists = {};

  int musicaAtual = 0;
  String pesquisa = '';

  bool estaTocando = false;
  bool modoAleatorio = false;
  bool repetirMusica = false;

  final Random _random = Random();

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

    carregarDados();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final favoritosSalvos =
        prefs.getStringList('favoritos') ?? [];

    final playlistsSalvas = prefs.getString('playlists');

    if (!mounted) return;

    setState(() {
      favoritos.addAll(favoritosSalvos);

      if (playlistsSalvas != null) {
        try {
          final Map<String, dynamic> dados =
              jsonDecode(playlistsSalvas);

          dados.forEach((nome, lista) {
            playlists[nome] = List<String>.from(lista);
          });
        } catch (_) {
          // Ignora dados antigos inválidos.
        }
      }
    });
  }

  Future<void> salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'favoritos',
      favoritos.toList(),
    );

    await prefs.setString(
      'playlists',
      jsonEncode(playlists),
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

  MusicVideo? encontrarMusica(String videoId) {
    for (final musica in musicas) {
      if (musica.videoId == videoId) {
        return musica;
      }
    }

    return null;
  }

  void tocarMusicaPorIndice(int indice) {
    if (indice < 0 || indice >= musicas.length) return;

    setState(() {
      musicaAtual = indice;
      estaTocando = true;
    });

    controller.loadVideoById(
      videoId: musicas[indice].videoId,
    );

    controller.playVideo();
  }

  void tocarMusica(String videoId) {
    final indice = musicas.indexWhere(
      (musica) => musica.videoId == videoId,
    );

    if (indice == -1) return;

    tocarMusicaPorIndice(indice);
  }

  void alternarPlayPause() {
    if (estaTocando) {
      controller.pauseVideo();

      setState(() {
        estaTocando = false;
      });
    } else {
      controller.playVideo();

      setState(() {
        estaTocando = true;
      });
    }
  }

  void proximaMusica() {
    int proxima;

    if (modoAleatorio && musicas.length > 1) {
      do {
        proxima = _random.nextInt(musicas.length);
      } while (proxima == musicaAtual);
    } else {
      proxima = musicaAtual + 1;

      if (proxima >= musicas.length) {
        proxima = 0;
      }
    }

    tocarMusicaPorIndice(proxima);
  }

  void musicaAnterior() {
    int anterior = musicaAtual - 1;

    if (anterior < 0) {
      anterior = musicas.length - 1;
    }

    tocarMusicaPorIndice(anterior);
  }

  void alternarAleatorio() {
    setState(() {
      modoAleatorio = !modoAleatorio;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          modoAleatorio
              ? 'Modo aleatório ativado'
              : 'Modo aleatório desativado',
        ),
      ),
    );
  }

  void alternarRepeticao() {
    setState(() {
      repetirMusica = !repetirMusica;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          repetirMusica
              ? 'Repetir música ativado'
              : 'Repetir música desativado',
        ),
      ),
    );
  }

  Future<void> alternarFavorito(MusicVideo musica) async {
    setState(() {
      if (favoritos.contains(musica.videoId)) {
        favoritos.remove(musica.videoId);
      } else {
        favoritos.add(musica.videoId);
      }
    });

    await salvarDados();
  }

  Future<void> criarPlaylist() async {
    final nomeController = TextEditingController();

    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova playlist'),
          content: TextField(
            controller: nomeController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nome da playlist',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text.trim();

                if (nome.isNotEmpty) {
                  Navigator.pop(context, nome);
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();

    if (nome == null || nome.isEmpty) return;

    if (playlists.containsKey(nome)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Essa playlist já existe.'),
        ),
      );

      return;
    }

    setState(() {
      playlists[nome] = [];
    });

    await salvarDados();
  }

  Future<void> adicionarNaPlaylist(MusicVideo musica) async {
    if (playlists.isEmpty) {
      await criarPlaylist();
    }

    if (!mounted || playlists.isEmpty) return;

    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Adicionar à playlist'),
          children: playlists.keys.map((nome) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, nome),
              child: Text(nome),
            );
          }).toList(),
        );
      },
    );

    if (nome == null) return;

    if (!playlists[nome]!.contains(musica.videoId)) {
      setState(() {
        playlists[nome]!.add(musica.videoId);
      });

      await salvarDados();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adicionada à playlist "$nome".'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Essa música já está na playlist.'),
        ),
      );
    }
  }

  Future<void> abrirPlaylists() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistPage(
          playlists: playlists,
          encontrarMusica: encontrarMusica,
          tocarMusica: tocarMusica,
          salvarDados: salvarDados,
          onPlaylistsChanged: () {
            setState(() {});
          },
        ),
      ),
    );

    setState(() {});
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
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Playlists',
            onPressed: abrirPlaylists,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova playlist',
            onPressed: criarPlaylist,
          ),
        ],
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
                  iconSize: 28,
                  tooltip: 'Aleatório',
                  onPressed: alternarAleatorio,
                  icon: Icon(
                    Icons.shuffle,
                    color: modoAleatorio
                        ? Colors.red
                        : Colors.white70,
                  ),
                ),

                IconButton(
                  iconSize: 34,
                  tooltip: 'Anterior',
                  onPressed: musicaAnterior,
                  icon: const Icon(Icons.skip_previous),
                ),

                const SizedBox(width: 8),

                IconButton(
                  iconSize: 48,
                  tooltip: 'Play/Pause',
                  onPressed: alternarPlayPause,
                  icon: Icon(
                    estaTocando
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  iconSize: 34,
                  tooltip: 'Próxima',
                  onPressed: proximaMusica,
                  icon: const Icon(Icons.skip_next),
                ),

                IconButton(
                  iconSize: 28,
                  tooltip: 'Repetir',
                  onPressed: alternarRepeticao,
                  icon: Icon(
                    Icons.repeat,
                    color: repetirMusica
                        ? Colors.red
                        : Colors.white70,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

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

            ...musicasFiltradas.map((item) {
              final indice = musicas.indexOf(item);
              final favorito =
                  favoritos.contains(item.videoId);

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
                      IconButton(
                        icon: const Icon(Icons.playlist_add),
                        color: Colors.white54,
                        onPressed: () {
                          adicionarNaPlaylist(item);
                        },
                      ),
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  onTap: () {
                    tocarMusicaPorIndice(indice);
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

class PlaylistPage extends StatefulWidget {
  final Map<String, List<String>> playlists;
  final MusicVideo? Function(String) encontrarMusica;
  final void Function(String) tocarMusica;
  final Future<void> Function() salvarDados;
  final VoidCallback onPlaylistsChanged;

  const PlaylistPage({
    super.key,
    required this.playlists,
    required this.encontrarMusica,
    required this.tocarMusica,
    required this.salvarDados,
    required this.onPlaylistsChanged,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  Future<void> excluirPlaylist(String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir playlist?'),
          content: Text(
            'A playlist "$nome" será removida.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() {
      widget.playlists.remove(nome);
    });

    await widget.salvarDados();
    widget.onPlaylistsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas playlists'),
      ),
      body: widget.playlists.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma playlist criada.',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: widget.playlists.keys.map((nome) {
                final lista = widget.playlists[nome]!;

                return Card(
                  color: const Color(0xff181818),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.queue_music,
                      color: Colors.red,
                    ),
                    title: Text(nome),
                    subtitle: Text(
                      '${lista.length} músicas',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        excluirPlaylist(nome);
                      },
                    ),
                    children: lista.map((videoId) {
                      final musica =
                          widget.encontrarMusica(videoId);

                      if (musica == null) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        title: Text(musica.titulo),
                        subtitle: Text(musica.artista),
                        leading: const Icon(
                          Icons.music_note,
                          color: Colors.red,
                        ),
                        trailing: const Icon(
                          Icons.play_arrow,
                          color: Colors.red,
                        ),
                        onTap: () {
                          // Agora envia o ID correto,
                          // e não o índice da playlist.
                          widget.tocarMusica(videoId);

                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
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
