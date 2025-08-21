import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:WordCard/main.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  late final Stream<List<Map<String, dynamic>>> _cardsStream;

  @override
  void initState() {
    super.initState();
    _cardsStream = supabase
        .from('word') 
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> _deleteCard(int id) async {
    try {
      await supabase.from('word').delete().match({'id': id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Card deleted"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to delete card"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  Future<void> _toggleMemorized(int id, bool currentStatus) async {
    try {
      await supabase
          .from('word')
          .update({'memorized': !currentStatus})
          .match({'id': id});
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to update status"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bizning so'zlar"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _cardsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final cards = snapshot.data!;
          if (cards.isEmpty) {
            return const Center(
              child: Text(
                "Siz so'z qoshmapsiz jigar\nGo asosiy bo'limga",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final isMemorized = card['memorized'] ?? false;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: IconButton(
                    icon: Icon(
                      isMemorized ? Icons.check_circle : Icons.check_circle_outline,
                      color: isMemorized ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleMemorized(card['id'], isMemorized),
                  ),
                  title: Text(
                    card['word'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    card['translation'],
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    onPressed: () => _deleteCard(card['id']),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(card['word']),
                        content: Text(card['definition'] ?? "Izohi yo'q."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Qaytish"),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ).animate().fade(delay: (100 * index).ms).slideX(begin: -0.2);
            },
          );
        },
      ),
    );
  }
}
