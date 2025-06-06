import 'package:flutter/material.dart';
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
      // Navigate to home (list of channels)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    // For Notifications and Account, you would typically navigate to those pages.
    // Since they are not implemented, we just update the selected index.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TED GO',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 0, 0)),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255), // Colore della freccia "indietro"
        ),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.redAccent,
      ),
      body: ListView.builder(
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
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3), // sfuma l’immagine per rendere leggibile il testo
                      BlendMode.darken,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(2, 4)),
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

// Assumo che Talk e WatchNextTalk siano definiti altrove

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

  @override
  void initState() {
    super.initState();
    _fetchTalk();
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchTalk();
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

      for (int i = 0; i < talks.length; i++) {
        final start = _parseSchedule(talks[i].schedule_time);
        final end =
            (i + 1 < talks.length) ? _parseSchedule(talks[i + 1].schedule_time) : start.add(const Duration(hours: 1));
        if (now.isAfter(start) && now.isBefore(end)) {
          current = talks[i];
          break;
        }
      }

      setState(() {
        currentTalk = current;
        isLoading = false;
        errorMessage = current == null ? "Nessun talk in onda al momento." : null;
      });
    } catch (e) {
      setState(() {
        currentTalk = null;
        isLoading = false;
        errorMessage = "Errore nel caricamento: ${e.toString()}";
      });
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
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255), // Colore della freccia "indietro"
        ),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text('Errore: $errorMessage'))
                : Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AllTalksPage(channel: widget.channel, displayName: widget.displayName),
                          ),
                        );
                      },
                      icon: const Icon(Icons.event_note),
                      label: const Text("Vedi programmazione"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 147, 94, 94),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentTalk != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TalkCard(talk: currentTalk!),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
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
                                icon: const Icon(Icons.playlist_play),
                                label: const Text("Guarda anche"),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Chat: commenta insieme alla community",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                height: 200,
                                width: 600,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 223, 185, 185),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(15),
                                child: const SingleChildScrollView(
                                  child: Text("⚠️ La chat non è ancora attiva.", style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: "Scrivi un messaggio...",
                                  prefixIcon: Icon(Icons.message),
                                  suffixIcon: Icon(Icons.send),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                enabled: false,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Text("Nessun talk in onda al momento."),
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
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
        selectedFontSize: 14,
        unselectedFontSize: 12,
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
  int _selectedIndex = 1; // Se vuoi default Notifiche, oppure cambia a 0 per Home ecc

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    // Puoi aggiungere navigazione per altre tab se vuoi
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
      body: Padding(
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
                    const Text(
                      "Guarda anche",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 212, 2, 2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 245, 245, 245),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
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
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
        selectedFontSize: 14,
        unselectedFontSize: 12,
      ),
    );
  }
}

class TalkCard extends StatelessWidget {
  final Talk talk;
  final VoidCallback? onTap;

  const TalkCard({Key? key, required this.talk, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(talk.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(talk.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(talk.schedule_time, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
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
        const Text("Consigliati:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...watchNextTalks.map((watch) => WatchNextTalkCard(talk: watch)).toList(),
      ],
    );
  }
}

class WatchNextTalkCard extends StatelessWidget {
  final WatchNextTalk talk;

  const WatchNextTalkCard({Key? key, required this.talk}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Azione da definire, es. aprire URL talk.url
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(talk.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(talk.url, style: const TextStyle(fontSize: 16, color: Colors.blue)),
            ],
          ),
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
  int _selectedIndex = 0; // For BottomNavigationBar

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
      // Navigate to home (list of channels)
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
        iconTheme: const IconThemeData(
          color: Colors.white, // Freccia indietro
        ),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.redAccent,
      ),
      body: FutureBuilder<List<Talk>>(
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

          // Trova il talk attualmente in onda
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

          // Filtra solo i successivi
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
                color: isNow ? Colors.blue[50] : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  title: Text(
                    "${isNow ? '🔴 In onda ora:\n' : ''}${talk.title}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isNow ? Colors.blue[800] : Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("🎤 ${talk.speakers}", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("🕒 ${talk.schedule_time}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
