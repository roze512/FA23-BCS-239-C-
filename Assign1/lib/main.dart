import 'package:flutter/material.dart';

void main() {
  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Professional Counter App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const CounterHomePage(title: 'Counter Application'),
    );
  }
}

class CounterHomePage extends StatefulWidget {
  const CounterHomePage({super.key, required this.title});
  final String title;

  @override
  State<CounterHomePage> createState() => _CounterHomePageState();
}

class _CounterHomePageState extends State<CounterHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() => _counter++);
  }

  void _decrementCounter() {
    setState(() => _counter--);
  }

  void _resetCounter() {
    setState(() => _counter = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Current Count',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$_counter',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Decrement
            FloatingActionButton(
              onPressed: _decrementCounter,
              heroTag: "decrement",
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 15),

            // Reset
            FloatingActionButton(
              onPressed: _resetCounter,
              heroTag: "reset",
              backgroundColor: Colors.orangeAccent,
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 15),

            // Increment
            FloatingActionButton(
              onPressed: _incrementCounter,
              heroTag: "increment",
              backgroundColor: Colors.greenAccent,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
