import 'dart:async';
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
        scaffoldBackgroundColor: const Color(0xFF090909),
        primaryColor: Colors.red,
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
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;

  final TextEditingController pesquisaController =
      TextEditingController();

  final Random _random = Random();

  final List<MusicVideo> musicas = [
    MusicVideo(
      titulo: 'The Weeknd - Blinding Lights',
      artista: 'The Weeknd',
      videoId: '4NRXx6U8ABQ',
    ),
    MusicVideo(
      titulo: 'Ed Sheeran - Shape of You',
      artista: 'Ed Sheeran',
      videoId: 'JGwWNGJdvx8',
    ),
    MusicVideo(
      titulo: 'Imagine Dragons - Believer',
      artista: 'Imagine Dragons',
      videoId: '7wtfhZwyrcc',
    ),
    MusicVideo(
      titulo: 'Luis Fonsi - Despacito',
      artista: 'Luis Fonsi',
      videoId: 'kJQP7kiw5Fk',
    ),
    MusicVideo(
      titulo: 'Maroon 5 - Sugar',
      artista: 'Maroon 5',
      videoId: '09R8_2nJtjg',
    ),
    MusicVideo(
      titulo: 'Avicii - Wake Me Up',
      artista: 'Avicii',
      videoId: 'IcrbM1l_BoI',
    ),
    MusicVideo(
      titulo: 'Alan Walker - Faded',
      artista: 'Alan Walker',
      videoId: '60ItHLz5WEA',
    ),
    MusicVideo(
      titulo: 'Coldplay - Viva La Vida',
      artista: 'Coldplay',
      videoId: 'dvgZkm1xWPE',
    ),
    MusicVideo(
      titulo: 'Bruno Mars - Just The Way You Are',
      artista: 'Bruno Mars',
      videoId: 'LjhCEhWiKXk',
    ),
    MusicVideo(
      titulo: 'OneRepublic - Counting Stars',
      artista: 'OneRepublic',
      videoId: 'hT_nvWreIhg',
    ),
  ];

  Set<String> favoritos = {};
  Map<String, List<String>> playlists = {};

  int musicaAtual = 0;
  String pesquisa = '';

  bool estaTocando = false;
  bool modoAleatorio = false;
  bool repetirMusica = false;

  List<int> fila = [];
  bool filaAtiva = false;

  @override
  void initState() {
    super.initState();

    controller = YoutubePlayerController.fromVideoId(
      videoId: musicas[musicaAtual].videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        mute: false,
        loop: false,
        enableCaption: false,
      ),
    );

    _playerSubscription = controller.listen((value) {
      if (!mounted) return;

      setState(() {
        estaTocando = value.playerState == PlayerState.playing;
      });

      if (value.playerState == PlayerState.ended) {
        proximaMusica();
      }
    });

    carregarDados();
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    controller.close();
    pesquisaController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final favoritosSalvos = prefs.getStringList('favoritos');
    final playlistsSalvas = prefs.getString('playlists');

    if (!mounted) return;

    setState(() {
      favoritos = favoritosSalvos?.toSet() ?? {};

      if (playlistsSalvas != null) {
        final dados = jsonDecode(playlistsSalvas);

        playlists = Map<String, List<String>>.from(
          dados.map(
            (chave, valor) => MapEntry(
              chave.toString(),
              List<String>.from(valor),
            ),
          ),
        );
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

  MusicVideo encontrarMusica(String videoId) {
    return musicas.firstWhere(
      (musica) => musica.videoId == videoId,
    );
  }

  String capaDaMusica(MusicVideo musica) {
    return 'https://img.youtube.com/vi/${musica.videoId}/hqdefault.jpg';
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

  void tocarMusica(MusicVideo musica) {
    final indice = musicas.indexWhere(
      (item) => item.videoId == musica.videoId,
    );

    if (indice != -1) {
      tocarMusicaPorIndice(indice);
    }
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
    if (musicas.isEmpty) return;

    int proxima;

    if (filaAtiva && fila.isNotEmpty) {
      proxima = fila.removeAt(0);

      if (fila.isEmpty) {
        filaAtiva = false;
      }
    } else if (modoAleatorio) {
      proxima = _random.nextInt(musicas.length);
    } else {
      proxima = musicaAtual + 1;

      if (proxima >= musicas.length) {
        if (repetirMusica) {
          proxima = 0;
        } else {
          proxima = musicas.length - 1;

          setState(() {
            estaTocando = false;
          });

          controller.pauseVideo();
          return;
        }
      }
    }

    tocarMusicaPorIndice(proxima);
  }

  void musicaAnterior() {
    if (musicas.isEmpty) return;

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
  }

  void alternarRepeticao() {
    setState(() {
      repetirMusica = !repetirMusica;
    });
  }

  void adicionarFila(MusicVideo musica) {
    final indice = musicas.indexWhere(
      (item) => item.videoId == musica.videoId,
    );

    if (indice == -1) return;

    setState(() {
      fila.add(indice);
      filaAtiva = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${musica.titulo} foi adicionada à fila',
        ),
      ),
    );
  }

  void adicionarUmaMusicaNaFila(MusicVideo musica) {
    adicionarFila(musica);
  }

  void abrirFila() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.queue_music),
                      SizedBox(width: 10),
                      Text(
                        'Fila de reprodução',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: fila.isEmpty
                      ? const Center(
                          child: Text(
                            'A fila está vazia',
                            style: TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: fila.length,
                          itemBuilder: (context, index) {
                            final musica = musicas[fila[index]];

                            return ListTile(
                              leading: Image.network(
                                capaDaMusica(musica),
                                width: 58,
                                height: 58,
                                fit: BoxFit.cover,
                              ),
                              title: Text(musica.titulo),
                              subtitle: Text(musica.artista),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    fila.removeAt(index);

                                    if (fila.isEmpty) {
                                      filaAtiva = false;
                                    }
                                  });

                                  Navigator.pop(context);
                                  abrirFila();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void alternarFavorito(MusicVideo musica) {
    setState(() {
      if (favoritos.contains(musica.videoId)) {
        favoritos.remove(musica.videoId);
      } else {
        favoritos.add(musica.videoId);
      }
    });

    salvarDados();
  }

  void criarPlaylist() {
    final nomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova playlist'),
          content: TextField(
            controller: nomeController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nome da playlist',
              prefixIcon: Icon(Icons.playlist_add),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text.trim();

                if (nome.isEmpty) return;

                if (playlists.containsKey(nome)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Já existe uma playlist com esse nome',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  playlists[nome] = [];
                });

                salvarDados();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Playlist "$nome" criada',
                    ),
                  ),
                );
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  void adicionarNaPlaylist(MusicVideo musica) {
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Crie uma playlist primeiro',
          ),
        ),
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Adicionar à playlist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...playlists.keys.map(
                (nome) {
                  final jaExiste =
                      playlists[nome]!.contains(musica.videoId);

                  return ListTile(
                    leading: const Icon(Icons.playlist_play),
                    title: Text(nome),
                    trailing: jaExiste
                        ? const Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : const Icon(Icons.add),
                    onTap: () {
                      if (!jaExiste) {
                        setState(() {
                          playlists[nome]!.add(musica.videoId);
                        });

                        salvarDados();

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Adicionada à playlist "$nome"',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void abrirPlaylists() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PlaylistPage(
            playlists: playlists,
            encontrarMusica: encontrarMusica,
            capaDaMusica: capaDaMusica,
            onTocarMusica: tocarMusica,
            onExcluirPlaylist: (nome) {
              setState(() {
                playlists.remove(nome);
              });

              salvarDados();
            },
            onRemoverMusica: (nome, videoId) {
              setState(() {
                playlists[nome]?.remove(videoId);
              });

              salvarDados();
            },
          );
        },
      ),
    );
  }

  void abrirAgoraTocando() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NowPlayingPage(
            obterMusicaAtual: () => musicas[musicaAtual],
            obterEstaTocando: () => estaTocando,
            obterModoAleatorio: () => modoAleatorio,
            obterRepetirMusica: () => repetirMusica,
            obterFavorito: () {
              return favoritos.contains(
                musicas[musicaAtual].videoId,
              );
            },
            capaDaMusica: capaDaMusica,
            onPlayPause: alternarPlayPause,
            onAnterior: musicaAnterior,
            onProxima: proximaMusica,
            onAleatorio: alternarAleatorio,
            onRepeticao: alternarRepeticao,
            onFavorito: () {
              alternarFavorito(musicas[musicaAtual]);
            },
            onAdicionarPlaylist: () {
              adicionarNaPlaylist(musicas[musicaAtual]);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musica = musicas[musicaAtual];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(
              Icons.music_note,
              color: Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              'PlayLivre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Fila',
            icon: const Icon(Icons.queue_music),
            onPressed: abrirFila,
          ),
          IconButton(
            tooltip: 'Playlists',
            icon: const Icon(Icons.library_music),
            onPressed: abrirPlaylists,
          ),
          IconButton(
            tooltip: 'Nova playlist',
            icon: const Icon(Icons.playlist_add),
            onPressed: criarPlaylist,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: abrirAgoraTocando,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: YoutubePlayer(
                        controller: controller,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              capaDaMusica(musica),
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  musica.titulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  musica.artista,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              favoritos.contains(musica.videoId)
                                  ? Icons.favorite
                                  : Icons.favorite_bor
