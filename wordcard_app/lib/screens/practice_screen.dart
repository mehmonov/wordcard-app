import 'dart:math';
import 'package:flutter/material.dart';
import 'package:WordCard/main.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Map<String, dynamic>? _currentCard;
  bool _isFlipped = false;
  bool _isLoading = true;
  bool _isTranslationRevealed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRandomCard();
  }

  Future<void> _fetchRandomCard() async {
    setState(() {
      _isLoading = true;
      _isFlipped = false;
      _isTranslationRevealed = false;
      _error = null;
    });

    try {
      final List<dynamic> allCards = await supabase
          .from('word')
          .select('id, word, translation, definition')
          .eq('user_id', supabase.auth.currentUser!.id);

      if (allCards.isEmpty) {
        setState(() => _error = "So'z qo'shmapsiz jigar, asosiy sahifaga sakrang");
      } else {
        final random = Random();
        setState(() {
          _currentCard = allCards[random.nextInt(allCards.length)];
        });
      }
    } catch (e) {
      setState(() => _error = "nimadir xato.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
      if (!_isFlipped) {
        _isTranslationRevealed = false;
      }
    });
  }

  void _revealTranslation() {
    setState(() {
      _isTranslationRevealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mashg'ulot"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: _buildCardContent(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchRandomCard,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text("Keyingisi"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_error != null) {
      return Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey));
    }
    if (_currentCard == null) {
      return const Text("Something went wrong.", style: TextStyle(fontSize: 18, color: Colors.grey));
    }

    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              final isUnder = (ValueKey(_isFlipped) != child!.key);
              var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
              tilt *= isUnder ? -1.0 : 1.0;
              final value = min(rotateAnim.value, pi / 2);
              return Transform(
                transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _isFlipped ? _buildBackCardFace(
          key: const ValueKey(true),
        ) : _buildCardFace(
          key: const ValueKey(false),
          word: _currentCard!['word'],
          label: 'Word',
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildCardFace({
    required Key key,
    required String word,
    required String label,
    required Color backgroundColor,
  }) {
    return Card(
      key: key,
      color: backgroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 8),
            Text(
              word,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCardFace({required Key key}) {
    return Card(
      key: key,
      color: Theme.of(context).colorScheme.secondary,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Definition',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentCard!['definition'] != null && _currentCard!['definition'].toString().isNotEmpty)
              Text(
                _currentCard!['definition'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'Translation',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _revealTranslation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _isTranslationRevealed 
                      ? Colors.transparent 
                      : Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: _isTranslationRevealed
                    ? Text(
                        _currentCard!['translation'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tarjimani ko\'rish',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}