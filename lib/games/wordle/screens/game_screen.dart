import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:all_in_one_games/core/services/token_service.dart';
import 'package:all_in_one_games/games/wordle/models/wordle_game.dart';
import 'package:all_in_one_games/games/wordle/models/wordle_skin.dart';
import 'package:all_in_one_games/games/wordle/services/word_list_service.dart';
import 'package:all_in_one_games/shared/themes/app_theme.dart';

const String _keyWordleWordNumber = 'wordle_word_number';
const String _keyWordleSkinIndex = 'wordle_skin_index';

class WordleGameScreen extends StatefulWidget {
  final int wordLength;

  const WordleGameScreen({
    super.key,
    this.wordLength = 5,
  });

  @override
  State<WordleGameScreen> createState() => _WordleGameScreenState();
}

class _WordleGameScreenState extends State<WordleGameScreen> {
  late WordListService _wordListService;
  late WordleGame _game;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isDialogOpen = false;
  bool _congratsShown = false;
  bool _lossShown = false;
  final Set<int> _revealedIndicesThisRound = {};
  int _currentWordNumber = 1;
  int _skinIndex = 0;

  static const double _standardButtonHeight = 36;
  static const double _standardButtonFontSize = 11;
  static const double _standardButtonIconSize = 12;
  static const double _standardButtonRadius = 12;
  static const double _dialogTitleFontSize = 16;
  static const double _dialogButtonFontSize = 14;

  static const Color _topSkinColor = Color(0xFFFF5252);
  static const Color _topTrialColor = Color(0xFFFFD700);
  static const Color _topRevealColor = Color(0xFF00FFCC);
  static const Color _bottomRestartColor = Color(0xFF00D9FF);
  static const Color _bottomLeaderboardColor = Color(0xFF00FF41);
  static const Color _bottomShopColor = Color(0xFFCCFF00);
  static const Color _bottomGameRuleColor = Color(0xFFFF6600);
  static const Color _bottomLeaveColor = Color(0xFFFF00FF);

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentWordNumber = (prefs.getInt(_keyWordleWordNumber) ?? 1).clamp(1, 999999);
      _skinIndex = (prefs.getInt(_keyWordleSkinIndex) ?? 0).clamp(0, wordleSkins.length - 1);
    });
  }

  Future<void> _saveWordNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWordleWordNumber, _currentWordNumber);
  }

  Future<void> _saveSkinIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWordleSkinIndex, _skinIndex);
  }

  Future<void> _initializeGame() async {
    await _loadSavedData();
    try {
      _wordListService = WordListService();
      await _wordListService.initialize();

      _game = WordleGame(wordLength: widget.wordLength);
      _startNewRound();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load word list: $e';
      });
    }
  }

  void _startNewRound() {
    if (!_isLoading && _game.targetWord.isNotEmpty) {
      setState(() => _currentWordNumber++);
      _saveWordNumber();
    }
    setState(() {
      _congratsShown = false;
      _lossShown = false;
      _revealedIndicesThisRound.clear();
    });
    final word = _wordListService.getRandomWord(widget.wordLength);
    if (word != null) {
      _game.startNewGame(word);
      if (kDebugMode) debugPrint('Wordle solution: ${_game.targetWord}');
    } else {
      setState(() => _errorMessage = 'No words available for length ${widget.wordLength}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('WORDLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 24)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('WORDLE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 24),
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _game,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 56,
                color: AppTheme.backgroundColor,
                alignment: Alignment.center,
                child: Text(
                  'Word $_currentWordNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                color: AppTheme.backgroundColor,
                child: Row(
                  children: [
                    Expanded(child: _panelButton(context, Icons.palette, 'Skin', () => _showSkinDialog(), _topSkinColor)),
                    const SizedBox(width: 6),
                    Expanded(child: _panelButton(context, Icons.add_circle_outline, 'Trial', null, _topTrialColor)),
                    const SizedBox(width: 6),
                    Expanded(child: _panelButton(context, Icons.lightbulb_outline, 'Reveal', null, _topRevealColor)),
                  ],
                ),
              ),
              Expanded(
                child: _WordleView(
                  skin: wordleSkins[_skinIndex.clamp(0, wordleSkins.length - 1)],
                  onNewGame: _startNewRound,
                  onShowCongrats: _showCongratsDialog,
                  onShowLoss: _showLossDialog,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 0),
                color: AppTheme.backgroundColor,
                child: Row(
                  children: [
                    Expanded(child: _panelButton(context, Icons.replay, 'Restart', () => _showRestartConfirm(), _bottomRestartColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _panelButton(context, Icons.leaderboard, 'Rank', () => _showRankDialog(), _bottomLeaderboardColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _panelButton(context, Icons.shopping_cart, 'Shop', () => _showShopDialog(), _bottomShopColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _panelButton(context, Icons.menu_book, 'Rules', () => _showRulesDialog(), _bottomGameRuleColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _panelButton(context, Icons.logout, 'Leave', () => _showLeaveConfirm(), _bottomLeaveColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelButton(BuildContext context, IconData icon, String label, VoidCallback? onPressed, Color themeColor) {
    return SizedBox(
      height: _standardButtonHeight,
      child: Material(
        color: onPressed != null ? themeColor.withValues(alpha: 0.5) : themeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(_standardButtonRadius),
        child: InkWell(
          onTap: _isDialogOpen ? null : onPressed,
          borderRadius: BorderRadius.circular(_standardButtonRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_standardButtonRadius),
              border: Border.all(color: themeColor, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: _standardButtonIconSize, color: themeColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: _standardButtonFontSize, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: themeColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSkinDialog() {
    setState(() => _isDialogOpen = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _topSkinColor, width: 2)),
        title: Center(child: Text('Choose Skin', style: TextStyle(color: _topSkinColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: wordleSkins.asMap().entries.map((e) {
              final i = e.key;
              final skin = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  tileColor: _skinIndex == i ? _topSkinColor.withValues(alpha: 0.2) : null,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: skin.correct, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 4),
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: skin.present, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 4),
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: skin.absent, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                  title: Text(skin.name, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      _skinIndex = i;
                      _saveSkinIndex();
                    });
                    Navigator.pop(ctx);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: _topSkinColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showRankDialog() {
    setState(() => _isDialogOpen = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _bottomLeaderboardColor, width: 2)),
        title: Center(child: Text('Rank', style: TextStyle(color: _bottomLeaderboardColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: const Text('Performance metrics coming soon.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: _bottomLeaderboardColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showShopDialog() {
    setState(() => _isDialogOpen = true);
    final themeColor = _bottomShopColor;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
          title: Center(child: Text('Shop', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${TokenService.getTokenCount()} ${TokenService.getTokenCount() == 1 ? "Token" : "Tokens"}',
                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                _shopRowWithIcon('Trial x 1', 1, () async {
                  if (!TokenService.canAfford(1)) return;
                  await TokenService.spendTokens(1);
                  _game.addExtraAttempt();
                  setDialogState(() {});
                }, themeColor),
                const Divider(color: Colors.white24),
                _shopRowWithIcon('Reveal x 1', 1, () => _buyReveal(ctx, 1, setDialogState), themeColor),
                _shopRowWithIcon('Reveal x 2', 2, () => _buyReveal(ctx, 2, setDialogState), themeColor),
                _shopRowWithIcon('Reveal x 5', 5, () => _buyReveal(ctx, 5, setDialogState), themeColor),
                _shopRowWithIcon('Reveal x 10', 10, () => _buyReveal(ctx, 10, setDialogState), themeColor),
                const Divider(color: Colors.white24),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Text('Buy Tokens', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                ...TokenService.tokenPacks.map((pack) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text('${pack.tokens} tokens', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text('\$${pack.usd.toStringAsFixed(0)}', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          await TokenService.addTokens(pack.tokens);
                          if (ctx.mounted) setDialogState(() {});
                        },
                        child: Text('Buy', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          ],
        ),
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  Future<void> _buyReveal(BuildContext ctx, int count, void Function(VoidCallback) setDialogState) async {
    final cost = count;
    if (!TokenService.canAfford(cost)) return;
    await TokenService.spendTokens(cost);
    setDialogState(() {});
    final word = _game.targetWord;
    if (word.isEmpty) return;
    final available = List<int>.generate(word.length, (i) => i).where((i) => !_revealedIndicesThisRound.contains(i)).toList();
    if (available.isEmpty) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('All positions already revealed.'), backgroundColor: Colors.orange));
      return;
    }
    available.shuffle(Random());
    final toReveal = available.take(count).toList();
    for (final i in toReveal) {
      _revealedIndicesThisRound.add(i);
    }
    final msg = toReveal.map((i) => 'Position ${i + 1} is \'${word[i]}\'').join('\n');
    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _bottomShopColor, duration: const Duration(seconds: 3)));
  }

  Widget _shopRowWithIcon(String title, int cost, VoidCallback onPurchase, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on, color: themeColor, size: 18),
              const SizedBox(width: 4),
              Text('$cost', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: TokenService.canAfford(cost) ? onPurchase : null,
            child: Text('Buy', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog() {
    setState(() => _isDialogOpen = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _bottomGameRuleColor, width: 2)),
        title: Center(child: Text('Rules', style: TextStyle(color: _bottomGameRuleColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: const SingleChildScrollView(
          child: Text(
            'Guess the word in 6 tries. Green: correct letter, correct position. Yellow: correct letter, wrong position. Gray: letter not in word.',
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: _bottomGameRuleColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showRestartConfirm() {
    setState(() => _isDialogOpen = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _bottomRestartColor, width: 2)),
        title: Center(child: Text('Restart?', style: TextStyle(color: _bottomRestartColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: const Text('Word number will reset to 1.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('No', style: TextStyle(color: _bottomRestartColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _isDialogOpen = false; _currentWordNumber = 0; });
              _saveWordNumber();
              _startNewRound();
            },
            child: Text('Yes', style: TextStyle(color: _bottomRestartColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showLeaveConfirm() {
    setState(() => _isDialogOpen = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _bottomLeaveColor, width: 2)),
        title: Center(child: Text('Leave game?', style: TextStyle(color: _bottomLeaveColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('No', style: TextStyle(color: _bottomLeaveColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: Text('Yes', style: TextStyle(color: _bottomLeaveColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showCongratsDialog(WordleGame game) {
    if (_congratsShown) return;
    _congratsShown = true;
    setState(() => _isDialogOpen = true);
    final themeColor = AppColors.correctGreen;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(child: Text('Congratulations', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize, letterSpacing: 1.2))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You guessed the word in ${game.attempts.length} ${game.attempts.length == 1 ? "try" : "tries"}!', style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isDialogOpen = false);
              _startNewRound();
            },
            child: Text('Play Again', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Back to Menu', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showLossDialog(WordleGame game) {
    if (_lossShown) return;
    _lossShown = true;
    setState(() => _isDialogOpen = true);
    final themeColor = Colors.red;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(child: Text('GAME OVER', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: _dialogTitleFontSize))),
        content: Text('The word was:\n\n${game.targetWord}', style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isDialogOpen = false);
              _startNewRound();
            },
            child: Text('Play Again', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Back to Menu', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }
}

class _WordleView extends StatelessWidget {
  final WordleSkin skin;
  final VoidCallback onNewGame;
  final void Function(WordleGame game) onShowCongrats;
  final void Function(WordleGame game) onShowLoss;

  const _WordleView({
    required this.skin,
    required this.onNewGame,
    required this.onShowCongrats,
    required this.onShowLoss,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WordleGame>(
      builder: (context, game, _) {
        if (game.isWon) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onShowCongrats(game));
        } else if (game.isLost) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onShowLoss(game));
        }

        return Column(
          children: [
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < game.maxAttempts; i++)
                        _WordRow(
                          skin: skin,
                          attempt: i < game.attempts.length
                              ? game.attempts[i]
                              : (i == game.attempts.length ? game.currentGuess : ''),
                          attemptIndex: i,
                          game: game,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _Keyboard(game: game, skin: skin),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _WordRow extends StatelessWidget {
  final WordleSkin skin;
  final String attempt;
  final int attemptIndex;
  final WordleGame game;

  const _WordRow({
    required this.skin,
    required this.attempt,
    required this.attemptIndex,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < game.wordLength; i++)
            _LetterBox(
              skin: skin,
              letter: i < attempt.length ? attempt[i] : '',
              status: attemptIndex < game.attempts.length
                  ? game.getLetterStatus(attemptIndex, i)
                  : LetterStatus.unknown,
            ),
        ],
      ),
    );
  }
}

class _LetterBox extends StatelessWidget {
  final WordleSkin skin;
  final String letter;
  final LetterStatus status;

  const _LetterBox({required this.skin, required this.letter, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    List<BoxShadow> shadows = [];

    switch (status) {
      case LetterStatus.correct:
        backgroundColor = skin.correct;
        textColor = Colors.white;
        shadows = [BoxShadow(color: skin.correct.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)];
        break;
      case LetterStatus.present:
        backgroundColor = skin.present;
        textColor = Colors.white;
        shadows = [BoxShadow(color: skin.present.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)];
        break;
      case LetterStatus.absent:
        backgroundColor = skin.absent;
        textColor = Colors.white;
        break;
      case LetterStatus.unknown:
        backgroundColor = AppTheme.backgroundColor;
        textColor = Colors.white;
        break;
    }

    return Container(
      width: 62,
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: status == LetterStatus.unknown
            ? Border.all(color: Colors.white, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
        boxShadow: shadows,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _Keyboard extends StatelessWidget {
  final WordleGame game;
  final WordleSkin skin;

  const _Keyboard({required this.game, required this.skin});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return _Key(
                  skin: skin,
                  letter: key,
                  onTap: () {
                    if (key == 'ENTER') {
                      game.submitGuess();
                    } else if (key == '⌫') {
                      game.removeLetter();
                    } else {
                      game.addLetter(key);
                    }
                  },
                  status: key.length == 1 ? game.getKeyboardLetterStatus(key) : LetterStatus.unknown,
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final WordleSkin skin;
  final String letter;
  final VoidCallback onTap;
  final LetterStatus status;

  const _Key({
    required this.skin,
    required this.letter,
    required this.onTap,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    List<BoxShadow> shadows = [];

    switch (status) {
      case LetterStatus.correct:
        backgroundColor = skin.correct;
        textColor = Colors.white;
        shadows = [BoxShadow(color: skin.correct.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)];
        break;
      case LetterStatus.present:
        backgroundColor = skin.present;
        textColor = Colors.white;
        shadows = [BoxShadow(color: skin.present.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)];
        break;
      case LetterStatus.absent:
        backgroundColor = skin.absent;
        textColor = Colors.white;
        break;
      case LetterStatus.unknown:
        backgroundColor = const Color(0xFF000000);
        textColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: letter.length > 1 ? 54 : 32,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: status == LetterStatus.unknown ? Colors.white : Colors.transparent,
            width: 1,
          ),
          boxShadow: shadows,
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: letter.length > 1 ? 10 : 17,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: letter.length > 1 ? 0.5 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
