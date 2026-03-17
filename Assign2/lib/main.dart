import 'package:flutter/material.dart';

void main() {
  runApp(const ProfileCardApp());
}

class ProfileCardApp extends StatelessWidget {
  const ProfileCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profile Card App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade400,
          surface: Colors.grey.shade900,
        ),
      ),
      home: const ProfileCardScreen(),
    );
  }
}

class ProfileCardScreen extends StatefulWidget {
  const ProfileCardScreen({super.key});

  @override
  State<ProfileCardScreen> createState() => _ProfileCardScreenState();
}

class _ProfileCardScreenState extends State<ProfileCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const ProfileCard(),
                          const SizedBox(height: 40),
                          const SocialMediaLinks(),
                          const SizedBox(height: 30),
                          const AdditionalStats(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProfileCard extends StatefulWidget {
  const ProfileCard({super.key});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_isHovered ? 0.1 : 0)
          ..rotateY(_isHovered ? 0.1 : 0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade900,
                Colors.grey.shade800,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.blue.shade400.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade400.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.purple.shade400.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.purple.shade400,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade800,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey.shade700,
                      child: ClipOval(
                        child: Image.asset(
                          'images/profile_pic.png',
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person,
                                size: 60, color: Colors.white);
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade400,
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                'Muhammad Rizwan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.blue.shade300, Colors.cyan.shade300],
                ).createShader(bounds),
                child: const Text(
                  'Full-Stack Developer | Creative Designer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                width: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.blue.shade400,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const ContactInfoRow(
                icon: Icons.email_rounded,
                label: 'Email',
                value: 'rizwan@comsats.edu.pk',
              ),
              const SizedBox(height: 12),
              const ContactInfoRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: '+92 321 8765432',
              ),
              const SizedBox(height: 12),
              const ContactInfoRow(
                icon: Icons.location_on_rounded,
                label: 'Location',
                value: 'Lahore, Pakistan',
              ),
              const SizedBox(height: 25),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionButton(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    color: Colors.blue.shade400,
                  ),
                  ActionButton(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: Colors.green.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ContactInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400.withOpacity(0.2),
                Colors.cyan.shade400.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade300,
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.label} tapped!'),
              duration: const Duration(milliseconds: 800),
              backgroundColor: widget.color,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialMediaLinks extends StatelessWidget {
  const SocialMediaLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        SocialButton(
          icon: Icons.language,
          label: 'Portfolio',
          color: Colors.blue.shade400,
        ),
        SocialButton(
          icon: Icons.account_circle,
          label: 'GitHub',
          color: Colors.grey.shade400,
        ),
        SocialButton(
          icon: Icons.work,
          label: 'LinkedIn',
          color: Colors.blue.shade600,
        ),
        SocialButton(
          icon: Icons.code,
          label: 'Twitter',
          color: Colors.cyan.shade400,
        ),
      ],
    );
  }
}

class SocialButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${widget.label}...'),
              duration: const Duration(milliseconds: 800),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.2 : 1.0),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.6),
                ],
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class AdditionalStats extends StatelessWidget {
  const AdditionalStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900.withOpacity(0.6),
            Colors.grey.shade800.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade400.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: const Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 20,
        runSpacing: 20,
        children: [
          StatItem(
            number: '2+',
            label: 'Years',
            icon: Icons.calendar_month_rounded,
          ),
          StatItem(
            number: '15+',
            label: 'Projects',
            icon: Icons.folder_rounded,
          ),
          StatItem(
            number: '3.96',
            label: 'CGPA',
            icon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;

  const StatItem({
    super.key,
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.blue.shade400,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
