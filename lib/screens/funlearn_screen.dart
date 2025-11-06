import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/funlearn_provider.dart';
import '../widgets/app_background.dart';

class FunLearnScreen extends StatelessWidget {
  static const routeName = '/funlearn';
  const FunLearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fl = context.watch<FunLearnProvider>();
    const subjects = ['Math', 'Science', 'English', 'GK'];
    return Scaffold(
      appBar: AppBar(title: const Text('FunLearn')),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: subjects
                            .map((s) => ChoiceChip(
                                  label: Text(s),
                                  selected: fl.subject == s,
                                  onSelected: (_) => context.read<FunLearnProvider>().setSubject(s),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_emotions),
                  title: const Text('Tell me a joke'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Why did the math book look sad? It had too many problems!'))),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.quiz),
                  title: const Text('Quick quiz'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.read<FunLearnProvider>().addScore(5),
                ),
              ),
              const Spacer(),
              Text('Score: ${fl.score}', style: const TextStyle(fontWeight: FontWeight.w600))
            ],
          ),
        ),
      ),
    );
  }
}


