import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/login/presentation/pages/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  
  // Slide Animations (Translation from outside)
  late Animation<Offset> _tlSlide, _trSlide, _brSlide, _blSlide;
  // Scale Animations (Growing from 0)
  late Animation<double> _scaleAnim;
  
  late AnimationController _textController;
  late Animation<double> _fadeTextAnimation;
  late Animation<Offset> _slideTextAnimation;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // 1. Main Logo Controller (Unified for stricter coordination)
    _mainController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    // Common Curve
    final curved = CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack);

    // Initialize Slide Animations (Move from corners to center)
    // Offset values are relative to the widget size
    _tlSlide = Tween<Offset>(begin: const Offset(-1.5, -1.5), end: Offset.zero)
        .animate(curved);
    _trSlide = Tween<Offset>(begin: const Offset(1.5, -1.5), end: Offset.zero)
        .animate(curved);
    _brSlide = Tween<Offset>(begin: const Offset(1.5, 1.5), end: Offset.zero)
        .animate(curved);
    _blSlide = Tween<Offset>(begin: const Offset(-1.5, 1.5), end: Offset.zero)
        .animate(curved);

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curved);


    // 2. Text Controller (Delay start slightly)
    _textController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    
    _fadeTextAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    
    _slideTextAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Start Sequence
    // Ensure the widget is built before starting animation to avoid "skip" on mobile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mainController.forward();
      }
    });
    
    // Start text after logo connects
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });

    // Navigate
    Timer(const Duration(seconds: 4), () {
       if (mounted) {
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
       }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), 
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Center Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              AnimatedLogo(
                tl: _tlSlide, tr: _trSlide, br: _brSlide, bl: _blSlide,
                scale: _scaleAnim,
                size: 80,
              ),
              
              const SizedBox(height: 40),
              
              // Text
              SlideTransition(
                position: _slideTextAnimation,
                child: FadeTransition(
                  opacity: _fadeTextAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'SMART CITY',
                        style: TextStyle(
                          fontFamily: 'Roboto', 
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Loading Indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
               opacity: _fadeTextAnimation, // Fade in with text
               child: const Column(
                children: [
                  PulsingDots(),
                  SizedBox(height: 20),
                  Text(
                    'Initializing Environment...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class AnimatedLogo extends StatelessWidget {
  final Animation<Offset> tl, tr, br, bl;
  final Animation<double> scale;
  final double size;

  const AnimatedLogo({
    super.key,
    required this.tl, required this.tr, required this.br, required this.bl,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final halfSize = size / 2;
    final gap = size * 0.05;
    final pieceSize = halfSize - gap;

    return SizedBox(
      width: size,
      height: size,
      child: ScaleTransition(
        scale: scale,
        child: Stack(
          children: [
            // Top Left (Blue)
            Positioned(
              top: 0, left: 0,
              child: SlideTransition(
                  position: tl,
                  child: LogoPiece(
                    width: pieceSize, height: pieceSize,
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(size * 0.1),
                      bottomRight: Radius.circular(size * 0.05),
                    ),
                  ),
                ),
            ),
            // Top Right (Green)
            Positioned(
              top: 0, right: 0,
              child: SlideTransition(
                position: tr,
                child: LogoPiece(
                  width: pieceSize, height: pieceSize,
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(size * 0.3),
                    bottomLeft: Radius.circular(size * 0.05),
                  ),
                ),
              ),
            ),
            // Bottom Right (Red)
            Positioned(
              bottom: 0, right: 0,
              child: SlideTransition(
                position: br,
                child: LogoPiece(
                  width: pieceSize, height: pieceSize,
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(size * 0.1),
                    topLeft: Radius.circular(size * 0.05),
                  ),
                ),
              ),
            ),
            // Bottom Left (Grey)
            Positioned(
              bottom: 0, left: 0,
              child: SlideTransition(
                position: bl,
                child: LogoPiece(
                  width: pieceSize, height: pieceSize,
                  color: const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(size * 0.1),
                    topRight: Radius.circular(size * 0.05),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogoPiece extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final BorderRadiusGeometry borderRadius;

  const LogoPiece({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 0),
          )
        ],
      ),
    );
  }
}

class PulsingDots extends StatefulWidget {
  const PulsingDots({super.key});

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // Calculate opacity for wave effect
            double value = (_controller.value + (index * 0.2)) % 1.0;
            // Create a smooth bell curve for opacity (0 -> 1 -> 0)
            double opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3 + (opacity * 0.7)), // Min 0.3, Max 1.0
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
