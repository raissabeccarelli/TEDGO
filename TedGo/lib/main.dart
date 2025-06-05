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
        title: const Text('TED GO', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        itemCount: MyHomePage.channelNames.length,
        itemBuilder: (context, index) {
          final channelKey = MyHomePage.channelNames.keys.elementAt(index);
          final displayName = MyHomePage.channelNames[channelKey]!;

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
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(2, 4)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Text(
                  displayName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
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
  int _selectedIndex = 0; // For BottomNavigationBar

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
        final talkStart = _parseSchedule(talks[i].schedule_time);

        final talkEnd =
            (i + 1 < talks.length)
                ? _parseSchedule(talks[i + 1].schedule_time)
                : talkStart.add(const Duration(hours: 1)); // se ultimo, supponi 1h

        if (now.isAfter(talkStart) && now.isBefore(talkEnd)) {
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
    if (index == 0) {
      // Navigate to home (list of channels)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentTalk != null)
                      // Wrap the content that might overflow in an Expanded widget
                      Expanded(
                        child: SingleChildScrollView(
                          // Add SingleChildScrollView to make the content scrollable if needed
                          child: Column(
                            children: [
                              TalkCard(talk: currentTalk!),
                              const SizedBox(height: 24),
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: const Text(
                                  "Chat: commenta insieme alla community",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),

                              Container(
                                height: 200,
                                width: 600,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(15),
                                child: const SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Placeholder per messaggi
                                      Text("⚠️ La chat non è ancora attiva.", style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
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
                                enabled: false, // Disabilitato perché è solo placeholder
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class TalkCard extends StatelessWidget {
  final Talk talk;

  const TalkCard({super.key, required this.talk});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(talk.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Speaker: ${talk.speakers}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(talk.description, style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 8),
            Text("📅 ${talk.schedule_time}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
      appBar: AppBar(title: Text("Programmazione: ${widget.displayName}"), backgroundColor: Colors.blue),
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifiche'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}