import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'talk_repository.dart';
import 'models/talk.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'MyTEDx', theme: ThemeData(primarySwatch: Colors.blue), home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  static const Map<String, String> channelNames = {
    'arte_design': 'Arte',
    'sports_health': 'Sport & Salute',
    'economics_business': 'Economia',
    'science': 'Scienza',
    'education': 'Educazione',
    'entertainment': 'Intrattenimento',
    'politics': 'Politica',
    'technology': 'Tecnologia',
  };

  static const Map<String, String> channelImages = {
    'arte_design': 'assets/images/arte.jpg',
    'sports_health': 'assets/images/sport.jpg',
    'economics_business': 'assets/images/economia.jpg',
    'science': 'assets/images/scienza.jpg',
    'education': 'assets/images/edu.jpg',
    'entertainment': 'assets/images/intrat.jpg',
    'politics': 'assets/images/politica.jpg',
    'technology': 'assets/images/tec.jpg',
  };

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TED GO',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 0, 0)),
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.redAccent,
      ),
      body: Container(
        color: const Color.fromARGB(255, 18, 18, 18),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: MyHomePage.channelNames.length,
          itemBuilder: (context, index) {
            final channelKey = MyHomePage.channelNames.keys.elementAt(index);
            final displayName = MyHomePage.channelNames[channelKey]!;
            final backgroundImage = MyHomePage.channelImages[channelKey] ?? 'assets/images/default.jpg';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChannelTalkPage(channel: channelKey, displayName: displayName)),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(backgroundImage),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 2,
                        spreadRadius: 2,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 75, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 0, 0),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
        selectedFontSize: 14,
        unselectedFontSize: 12,
      ),
    );
  }
}

class ChannelTalkPage extends StatefulWidget {
  final String channel;
  final String displayName;

  const ChannelTalkPage({super.key, required this.channel, required this.displayName});

  @override
  State<ChannelTalkPage> createState() => _ChannelTalkPageState();
}

class _ChannelTalkPageState extends State<ChannelTalkPage> {
  Talk? currentTalk;
  Timer? timer;
  bool isLoading = true;
  String? errorMessage;
  int _selectedIndex = 0;

  late WebViewController _webViewController;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);

    _fetchTalk();
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndUpdateTalk();
    });
  }

  DateTime _parseSchedule(String schedule) {
    final regex = RegExp(r'Streaming at (\d{2}):(\d{2}) on (\d{2})/(\d{2})');
    final match = regex.firstMatch(schedule);
    if (match == null) throw FormatException("Formato orario non valido: $schedule");

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final month = int.parse(match.group(4)!);
    final now = DateTime.now();

    return DateTime(now.year, month, day, hour, minute);
  }

  Future<void> _fetchTalk() async {
    try {
      final talks = await get_Talks_By_Channel(widget.channel, 100);
      if (talks.isEmpty) {
        setState(() {
          currentTalk = null;
          isLoading = false;
          errorMessage = "Nessun talk trovato.";
        });
        return;
      }

      final now = DateTime.now();
      Talk? current;
      DateTime? startTime;

      for (int i = 0; i < talks.length; i++) {
        final start = _parseSchedule(talks[i].schedule_time);
        final end =
            (i + 1 < talks.length) ? _parseSchedule(talks[i + 1].schedule_time) : start.add(const Duration(hours: 1));
        if (now.isAfter(start) && now.isBefore(end)) {
          current = talks[i];
          startTime = start;
          break;
        }
      }

      setState(() {
        currentTalk = current;
        isLoading = false;
        errorMessage = current == null ? "Nessun talk in onda al momento." : null;
      });

      if (current != null && current.embedUrl != _currentVideoUrl && startTime != null) {
        final urlWithOffset = convertTedEmbedToWatchUrlWithOffset(current.embedUrl, startTime);
        _currentVideoUrl = urlWithOffset;
        _webViewController.loadRequest(Uri.parse(urlWithOffset));
      }
    } catch (e) {
      setState(() {
        currentTalk = null;
        isLoading = false;
        errorMessage = "Errore nel caricamento: ${e.toString()}";
      });
    }
  }

  Future<void> _checkAndUpdateTalk() async {
    try {
      final talks = await get_Talks_By_Channel(widget.channel, 100);
      if (talks.isEmpty) return;

      final now = DateTime.now();
      Talk? current;
      DateTime? startTime;

      for (int i = 0; i < talks.length; i++) {
        final start = _parseSchedule(talks[i].schedule_time);
        final end =
            (i + 1 < talks.length) ? _parseSchedule(talks[i + 1].schedule_time) : start.add(const Duration(hours: 1));
        if (now.isAfter(start) && now.isBefore(end)) {
          current = talks[i];
          startTime = start;
          break;
        }
      }
      if (current == null) return;
      if (current.id != currentTalk?.id && startTime != null) {
        setState(() {
          currentTalk = current;
          errorMessage = null;
        });
        final urlWithOffset = convertTedEmbedToWatchUrlWithOffset(current.embedUrl, startTime);
        _webViewController.loadRequest(Uri.parse(urlWithOffset));
      }
    } catch (e) {}
  }

  String convertTedEmbedToWatchUrlWithOffset(String embedUrl, DateTime startTime) {
    final now = DateTime.now();
    final offsetSeconds = now.difference(startTime).inSeconds.clamp(0, 86400);

    final regex = RegExp(r'talks/([^/?]+)');
    final match = regex.firstMatch(embedUrl);

    if (match != null) {
      final slug = match.group(1)!;
      return 'https://embed.ted.com/talks/$slug?language=en&t=$offsetSeconds';
    } else {
      // Fallback nel caso il formato non corrisponda esattamente
      final uri = Uri.parse(embedUrl);
      final newUri = uri.replace(
        queryParameters: {...uri.queryParameters, 't': offsetSeconds.toString(), 'language': 'en'},
      );
      return newUri.toString();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 0, 0)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.redAccent,
      ),
      body: Container(
        color: const Color.fromARGB(255, 18, 18, 18),
        padding: const EdgeInsets.all(16),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text('Errore: $errorMessage', style: const TextStyle(color: Colors.white)))
                : currentTalk == null
                ? const Center(child: Text("Nessun talk in onda al momento.", style: TextStyle(color: Colors.white)))
                : Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child:
                            _currentVideoUrl != null
                                ? WebViewWidget(controller: _webViewController)
                                : const Center(child: CircularProgressIndicator()),
                      ),
                    ),

                    const SizedBox(height: 12),
                    if (currentTalk != null) ...[
                      Text(
                        currentTalk!.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Speaker: ${currentTalk!.speakers}",
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => AllTalksPage(channel: widget.channel, displayName: widget.displayName),
                                ),
                              );
                            },
                            icon: const Icon(Icons.event_note),
                            label: const Text("Vedi programmazione"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.red, width: 1),
                              ),
                              elevation: 3,
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              try {
                                final watch = await get_WatchNext_By_ID(currentTalk!.id);
                                if (!mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => WatchNextPage(
                                          watchNextTalks: watch.cast<WatchNextTalk>(),
                                          channel: widget.channel,
                                          displayName: widget.displayName,
                                        ),
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  errorMessage = "Errore nel caricamento: ${e.toString()}";
                                });
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.video_collection),
                            label: const Text("Guarda anche"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.red, width: 1),
                              ),
                              elevation: 3,
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Chat: commenta insieme alla community",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(108, 108, 108, 108),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(15),
                        child: const SingleChildScrollView(
                          child: Text("⚠️ La chat non è ancora attiva.", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Scrivi un messaggio...",
                        prefixIcon: const Icon(Icons.message),
                        suffixIcon: const Icon(Icons.send),
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      enabled: false,
                    ),
                  ],
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
        selectedFontSize: 14,
        unselectedFontSize: 12,
      ),
    );
  }
}

class TedTalkPlayer extends StatelessWidget {
  final String embedUrl;

  const TedTalkPlayer({super.key, required this.embedUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riproduzione Talk")),
      body: WebViewWidget(
        controller:
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(Uri.parse(embedUrl)),
      ),
    );
  }
}

class WatchNextPage extends StatefulWidget {
  final List<WatchNextTalk> watchNextTalks;
  final String channel;
  final String displayName;

  const WatchNextPage({Key? key, required this.watchNextTalks, required this.channel, required this.displayName})
    : super(key: key);

  @override
  State<WatchNextPage> createState() => _WatchNextPageState();
}

class _WatchNextPageState extends State<WatchNextPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Consigliati',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 0, 0)),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Freccia indietro
        ),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.redAccent,
      ),
      body: Container(
        color: const Color.fromARGB(255, 18, 18, 18),
        padding: const EdgeInsets.all(16.0),
        child:
            widget.watchNextTalks.isEmpty
                ? const Center(
                  child: Text(
                    "Nessun talk consigliato.",
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        child: SingleChildScrollView(child: WatchNextTalkList(watchNextTalks: widget.watchNextTalks)),
                      ),
                    ),
                  ],
                ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 0, 0),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color.fromARGB(255, 18, 18, 18),
        onTap: _onItemTapped,
        selectedFontSize: 14,
        unselectedFontSize: 12,
      ),
    );
  }
}

class WatchNextTalkList extends StatelessWidget {
  final List<WatchNextTalk> watchNextTalks;

  const WatchNextTalkList({Key? key, required this.watchNextTalks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Guarda anche:",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFFF5252)),
        ),
        const SizedBox(height: 16),
        ...watchNextTalks.map(
          (watch) => Padding(padding: const EdgeInsets.only(bottom: 12), child: WatchNextTalkCard(talk: watch)),
        ),
      ],
    );
  }
}

class WatchNextTalkCard extends StatefulWidget {
  final WatchNextTalk talk;

  const WatchNextTalkCard({Key? key, required this.talk}) : super(key: key);

  @override
  State<WatchNextTalkCard> createState() => _WatchNextTalkCardState();
}

class _WatchNextTalkCardState extends State<WatchNextTalkCard> {
  bool _showPlayer = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(widget.talk.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 213, 213, 213),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.talk.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: const Color.fromARGB(255, 255, 0, 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red, width: 1),
                  ),
                  elevation: 3,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  setState(() {
                    _showPlayer = !_showPlayer;
                  });
                },
                icon: const Icon(Icons.play_circle),
                label: Text(_showPlayer ? 'Nascondi player' : 'Guarda il talk'),
              ),
            ),
            if (_showPlayer) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(height: 200, child: WebViewWidget(controller: _controller)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AllTalksPage extends StatefulWidget {
  final String channel;
  final String displayName;

  const AllTalksPage({super.key, required this.channel, required this.displayName});

  @override
  State<AllTalksPage> createState() => _AllTalksPageState();
}

class _AllTalksPageState extends State<AllTalksPage> {
  int _selectedIndex = 0;

  DateTime _parseSchedule(String schedule) {
    final regex = RegExp(r'Streaming at (\d{2}):(\d{2}) on (\d{2})/(\d{2})');
    final match = regex.firstMatch(schedule);

    if (match == null) {
      throw FormatException("Formato orario non valido: $schedule");
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final month = int.parse(match.group(4)!);
    final now = DateTime.now();

    return DateTime(now.year, month, day, hour, minute);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Programmazione',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 0, 0)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.redAccent,
      ),
      body: Container(
        color: const Color.fromARGB(255, 18, 18, 18),
        child: FutureBuilder<List<Talk>>(
          future: get_Talks_By_Channel(widget.channel, 100),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Errore: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Nessun talk disponibile."));
            }

            final talks = snapshot.data!;
            final now = DateTime.now();

            Talk? currentTalk;
            int currentIndex = -1;
            for (int i = 0; i < talks.length; i++) {
              final start = _parseSchedule(talks[i].schedule_time);
              final end =
                  (i + 1 < talks.length)
                      ? _parseSchedule(talks[i + 1].schedule_time)
                      : start.add(const Duration(hours: 1));

              if (now.isAfter(start) && now.isBefore(end)) {
                currentTalk = talks[i];
                currentIndex = i;
                break;
              }
            }

            final upcomingTalks =
                (currentIndex >= 0 && currentIndex + 1 < talks.length)
                    ? talks.sublist(currentIndex + 1)
                    : (currentIndex == -1
                        ? talks.where((talk) {
                          final start = _parseSchedule(talk.schedule_time);
                          return start.isAfter(now);
                        }).toList()
                        : []);

            final allToDisplay = [if (currentTalk != null) currentTalk, ...upcomingTalks];

            if (allToDisplay.isEmpty) {
              return const Center(child: Text("Nessun talk in programma."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: allToDisplay.length,
              itemBuilder: (context, index) {
                final talk = allToDisplay[index];
                final isNow = talk == currentTalk;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: isNow ? 5 : 3,
                  color: isNow ? const Color.fromARGB(255, 255, 219, 219) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    title: Text(
                      "${isNow ? '🔴 In onda ora:\n' : ''}${talk.title}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isNow ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("🎤 ${talk.speakers}", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          "🕒 ${talk.schedule_time}",
                          style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 0, 0),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
        selectedFontSize: 14,
        unselectedFontSize: 12,
      ),
    );
  }
}
