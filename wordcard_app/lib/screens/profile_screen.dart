import 'package:flutter/material.dart';
import 'package:WordCard/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, int>> _fetchStats() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final responses = await Future.wait([
        supabase.from('word').count(CountOption.exact).eq('user_id', userId),
        supabase.from('word').count(CountOption.exact).eq('user_id', userId).eq('memorized', true),
      ]);

      final totalCards = responses[0];
      final memorizedCards = responses[1];

      return {
        'total': totalCards,
        'memorized': memorizedCards,
      };
    } catch (e) {
      return {'total': 0, 'memorized': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userEmail = user?.email ?? ''; 
    final userAvatarUrl = user?.userMetadata?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Column(
            children: [
              if (userAvatarUrl != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(userAvatarUrl),
                )
              else
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    // RangeError xatoligini tuzatish
                    userEmail.isNotEmpty ? userEmail.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                userEmail.isNotEmpty ? userEmail : "Foydalanuvchi",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            "Statistika",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, int>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final total = snapshot.data?['total'] ?? 0;
              final memorized = snapshot.data?['memorized'] ?? 0;

              return Card(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.style_outlined),
                      title: const Text("Umumiy so'zlar"),
                      trailing: Text(
                        total.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: const Text("Eslab qolingan"),
                      trailing: Text(
                        memorized.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text("Chiqish"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          )
        ],
      ),
    );
  }
}
