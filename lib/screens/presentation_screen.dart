import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ponto_cantado.dart';
import '../models/ponto_item.dart';

class PresentationScreen extends StatefulWidget {
  final List<PontoItem> pontos;
  final String title;

  const PresentationScreen({super.key, required this.pontos, required this.title});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isPlaying = false;
  double _scrollSpeed = 1.0;
  double _fontSize = 24.0;
  Timer? _scrollTimer;
  Timer? _manualScrollTimer;

  bool _isManualScrolling = false;

  @override
  void initState() {
    super.initState();
    // Esconde a barra inferior de navegação e a barra de status. 
    // Quando deslizado, aparece por alguns segundos e volta a esconder.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isManualScrolling && _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        double nextOffset = _scrollController.offset + (_scrollSpeed * 0.5); // Adjust multiplier for slower min speed
        if (nextOffset >= _scrollController.position.maxScrollExtent) {
          _stopAutoScroll();
          setState(() => _isPlaying = false);
        } else {
          _scrollController.jumpTo(nextOffset);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
  }

  void _startManualScroll(bool up) {
    _isManualScrolling = true;
    _manualScrollTimer?.cancel();
    _manualScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        double offsetDelta = 15.0; // Velocidade do scroll manual (rebobinar/avançar)
        double nextOffset = _scrollController.offset + (up ? -offsetDelta : offsetDelta);
        
        if (nextOffset <= 0) {
           _scrollController.jumpTo(0);
           _stopManualScroll();
        } else if (nextOffset >= _scrollController.position.maxScrollExtent) {
           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
           _stopManualScroll();
        } else {
           _scrollController.jumpTo(nextOffset);
        }
      }
    });
  }

  void _stopManualScroll() {
    _isManualScrolling = false;
    _manualScrollTimer?.cancel();
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize += 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 10.0) _fontSize -= 2.0;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _manualScrollTimer?.cancel();
    _scrollController.dispose();
    // Restaura a interface normal quando sair da tela de apresentação
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 18)),
        toolbarHeight: 40, // Deixa o appBar mais fino
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0), // Menor altura
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                  tooltip: _isPlaying ? 'Pausar' : 'Iniciar',
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Slider(
                    value: _scrollSpeed,
                    min: 0.05, // Menor valor para rolagem bem mais lenta
                    max: 5.0,
                    onChanged: (value) {
                      setState(() {
                        _scrollSpeed = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: _decreaseFontSize,
                  tooltip: 'Diminuir fonte',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: _increaseFontSize,
                  tooltip: 'Aumentar fonte',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: widget.pontos.length,
            itemBuilder: (context, index) {
              final pontoItem = widget.pontos[index];
              final letra = pontoItem.ponto.pontoLetra.trim();
              
              if (letra.isEmpty) {
                return const SizedBox.shrink();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 24.0),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    letra,
                    style: TextStyle(fontSize: _fontSize, height: 1.5),
                    textAlign: TextAlign.left, // Alinhado à esquerda
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _scrollToTop, // Clique simples: vai para o topo
                  onLongPressStart: (_) => _startManualScroll(true), // Segurar: rebobina (sobe)
                  onLongPressEnd: (_) => _stopManualScroll(), // Soltar: volta ao estado normal
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _scrollToBottom, // Clique simples: vai para o rodapé
                  onLongPressStart: (_) => _startManualScroll(false), // Segurar: avança (desce)
                  onLongPressEnd: (_) => _stopManualScroll(), // Soltar: volta ao estado normal
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
