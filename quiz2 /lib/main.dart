import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DiceHomePage(),
    );
  }
}

class DiceHomePage extends StatefulWidget {
  const DiceHomePage({super.key});

  @override
  State<DiceHomePage> createState() => _DiceHomePageState();
}

class _DiceHomePageState extends State<DiceHomePage>
    with TickerProviderStateMixin {

  int diceNumber = 1;

  late AnimationController _rotationController;
  late AnimationController _bounceController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _rotationAnimation =
        Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeOut,
      ),
    );

    // Bounce animation (real dice feel)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bounceAnimation =
        Tween<double>(begin: 0, end: -25).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOut,
      ),
    );
  }

  void rollDice() async {
    _rotationController.forward(from: 0);
    await _bounceController.forward(from: 0);
    _bounceController.reverse();

    setState(() {
      diceNumber = Random().nextInt(6) + 1;
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        // Background Gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Dice Roller",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 50),

              // 🎲 White Dice Block
              GestureDetector(
                onTap: rollDice,
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                      [_rotationController, _bounceController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3), // ✅ FIXED
                          blurRadius: 20,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/$diceNumber.png',
                      height: 140,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "You rolled: $diceNumber",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: rollDice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
                child: const Text(
                  "ROLL DICE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}