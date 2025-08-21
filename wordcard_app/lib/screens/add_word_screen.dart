import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:WordCard/main.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _translationController = TextEditingController();
  final _definitionController = TextEditingController();
  bool _isMemorized = false;
  bool _isLoading = false;

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("No logged in user");
    }
    try {
      await supabase.from('word').insert({
        'word': _wordController.text.trim(),
        'translation': _translationController.text.trim(),
        'definition': _definitionController.text.trim(),
        'memorized': _isMemorized,
        'user_id': user.id,  
      
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saqlandi!"),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _wordController.clear();
        _translationController.clear();
        _definitionController.clear();
        setState(() {
          _isMemorized = false;
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${error.message}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("An unexpected error occurred"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yangi qo'shish"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _wordController,
                  decoration: const InputDecoration(
                    labelText: "Word",
                    border: OutlineInputBorder(),
                    hintText: "e.g., Olma",
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Bo'sh bo'masin lekin" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _translationController,
                  decoration: const InputDecoration(
                    labelText: "Tarjimas",
                    border: OutlineInputBorder(),
                    hintText: "e.g., Apple",
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "This field cannot be empty" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _definitionController,
                  decoration: const InputDecoration(
                    labelText: "Definition / Tarif",
                    border: OutlineInputBorder(),
                    hintText: "e.g., A round fruit with firm, white flesh...",
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Eslab qolindi"),
                  value: _isMemorized,
                  onChanged: (bool value) {
                    setState(() {
                      _isMemorized = value;
                    });
                  },
                  secondary: Icon(
                    _isMemorized ? Icons.check_circle : Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _saveCard,
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text("Saqlandi"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
