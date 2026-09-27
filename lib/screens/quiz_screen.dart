import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/answer_record.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;

  final List<AnswerRecord> _records = [];

  Question get _currentQuestion => widget.questions[_currentIndex];

  void _selectOption(int index) {
    if (_answered) return; // cevap verildikten sonra şık değiştirilemez
    setState(() {
      _selectedOption = index;
      _answered = true;
      _records.add(AnswerRecord(
        category: _currentQuestion.category,
        isCorrect: index == _currentQuestion.correctIndex,
      ));
    });
  }

  void _nextQuestion() {
    if (_currentIndex == widget.questions.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(records: _records)),
      );
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _answered = false;
    });
  }

  Color? _optionColor(int index) {
    if (!_answered) return null;
    if (index == _currentQuestion.correctIndex) return Colors.green;
    if (index == _selectedOption) return Colors.red;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${_currentIndex + 1} / ${widget.questions.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 8),
            Text(q.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ...List.generate(q.options.length, (index) {
              final color = _optionColor(index);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: color?.withValues(alpha: 0.15),
                    side: BorderSide(color: color ?? Colors.grey, width: color != null ? 2 : 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => _selectOption(index),
                  child: Text(q.options[index]),
                ),
              );
            }),
            const Spacer(),
            if (_answered)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextQuestion,
                  child: Text(_currentIndex == widget.questions.length - 1
                      ? 'Sınavı Bitir'
                      : 'Sonraki Soru'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
