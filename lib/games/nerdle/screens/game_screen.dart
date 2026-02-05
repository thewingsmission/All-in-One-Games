import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:all_in_one_games/core/services/token_service.dart';
import 'package:all_in_one_games/games/nerdle/models/nerdle_game.dart';
import 'package:all_in_one_games/games/nerdle/services/equation_service.dart';
import 'package:all_in_one_games/shared/themes/app_theme.dart';

const String _keyNerdleFormulaNumber = 'nerdle_formula_number';

/// Returns equation length (5–15) for the given formula number (1-based) per progression table.
int _equationLengthForFormulaNumber(int formulaNumber) {
  final rand = Random();
  List<({int length, int weight})> dist;
  if (formulaNumber <= 10) {
    dist = [(length: 5, weight: 50), (length: 6, weight: 50)];
  } else if (formulaNumber <= 20) {
    dist = [(length: 6, weight: 50), (length: 7, weight: 50)];
  } else if (formulaNumber <= 30) {
    dist = [(length: 6, weight: 10), (length: 7, weight: 60), (length: 8, weight: 30)];
  } else if (formulaNumber <= 40) {
    dist = [(length: 7, weight: 50), (length: 8, weight: 30), (length: 9, weight: 20)];
  } else if (formulaNumber <= 50) {
    dist = [(length: 7, weight: 30), (length: 8, weight: 40), (length: 9, weight: 20), (length: 10, weight: 10)];
  } else if (formulaNumber <= 60) {
    dist = [(length: 7, weight: 10), (length: 8, weight: 30), (length: 9, weight: 30), (length: 10, weight: 30)];
  } else if (formulaNumber <= 70) {
    dist = [(length: 8, weight: 30), (length: 9, weight: 30), (length: 10, weight: 30), (length: 11, weight: 10)];
  } else if (formulaNumber <= 80) {
    dist = [(length: 8, weight: 25), (length: 9, weight: 25), (length: 10, weight: 25), (length: 11, weight: 15), (length: 12, weight: 10)];
  } else {
    dist = [(length: 8, weight: 20), (length: 9, weight: 20), (length: 10, weight: 20), (length: 11, weight: 20), (length: 12, weight: 20)];
  }
  final total = dist.fold<int>(0, (s, e) => s + e.weight);
  int r = rand.nextInt(total);
  for (final e in dist) {
    if (r < e.weight) return e.length;
    r -= e.weight;
  }
  return dist.last.length;
}

class NerdleGameScreen extends StatefulWidget {
  /// If null, use formula progression (Formula 1, 2, ...). If set, single puzzle at that length (legacy).
  final int? equationLength;

  const NerdleGameScreen({
    super.key,
    this.equationLength,
  });

  @override
  State<NerdleGameScreen> createState() => _NerdleGameScreenState();
}

class _NerdleGameScreenState extends State<NerdleGameScreen> {
  late EquationService _equationService;
  late NerdleGame _game;
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentFormulaNumber = 1;
  bool _isDialogOpen = false;
  bool _congratsShownForCurrentFormula = false;
  bool _lossShownForCurrentFormula = false;
  final Set<int> _revealedIndicesThisRound = {};

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
      _currentFormulaNumber = (prefs.getInt(_keyNerdleFormulaNumber) ?? 1).clamp(1, 999999);
    });
  }

  Future<void> _saveFormulaNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNerdleFormulaNumber, _currentFormulaNumber);
  }

  Future<void> _initializeGame() async {
    await _loadSavedData();
    try {
      _equationService = EquationService();
      await _equationService.initialize();

      final length = widget.equationLength ?? _equationLengthForFormulaNumber(_currentFormulaNumber);
      _game = NerdleGame(equationLength: length);
      _startNewRound();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load equations: $e';
      });
    }
  }

  void _startNewRound() {
    if (!_isLoading && _game.targetEquation.isNotEmpty) {
      setState(() => _currentFormulaNumber++);
      _saveFormulaNumber();
    }
    setState(() {
      _congratsShownForCurrentFormula = false;
      _lossShownForCurrentFormula = false;
      _revealedIndicesThisRound.clear();
    });
    final length = widget.equationLength ?? _equationLengthForFormulaNumber(_currentFormulaNumber);
    _game = NerdleGame(equationLength: length);
    final equation = _equationService.getRandomEquation(length);
    if (equation != null) {
      _game.startNewGame(equation);
      if (kDebugMode) debugPrint('Nerdle solution: $equation');
    } else {
      setState(() => _errorMessage = 'No equations available for length $length');
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
              const Text('NERDLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 24)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppTheme.primaryOrange),
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
                const Text('NERDLE', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                  'Formula $_currentFormulaNumber',
                  style: const TextStyle(
                    fontFamily: 'Arial',
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
                child: _NerdleView(
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
        color: onPressed != null ? themeColor.withOpacity(0.5) : themeColor.withOpacity(0.2),
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
        title: Center(child: Text('Choose Skin Style', style: TextStyle(color: _topSkinColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: const Text('Skin options coming soon.', style: TextStyle(color: Colors.white)),
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
        content: const Text('Performance metrics (Formula) coming soon.', style: TextStyle(color: Colors.white)),
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
    final eq = _game.targetEquation;
    if (eq.isEmpty) return;
    final available = List<int>.generate(eq.length, (i) => i).where((i) => !_revealedIndicesThisRound.contains(i)).toList();
    if (available.isEmpty) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('All positions already revealed.'), backgroundColor: Colors.orange));
      return;
    }
    available.shuffle(Random());
    final toReveal = available.take(count).toList();
    for (final i in toReveal) {
      _revealedIndicesThisRound.add(i);
    }
    final msg = toReveal.map((i) => 'Position ${i + 1} is \'${eq[i]}\'').join('\n');
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
            'Guess the equation. Green: correct character, correct position. Yellow: in equation, wrong position. Gray: not in equation. Must be a valid equation with =. Order of operations: x and ÷ before + and -.',
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
        content: const Text('Formula number will reset to 1.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('No', style: TextStyle(color: _bottomRestartColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _isDialogOpen = false; _currentFormulaNumber = 0; });
              _saveFormulaNumber();
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

  void _showCongratsDialog(NerdleGame game) {
    if (_congratsShownForCurrentFormula) return;
    _congratsShownForCurrentFormula = true;
    setState(() => _isDialogOpen = true);
    final themeColor = AppTheme.primaryOrange;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Congratulations',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize, letterSpacing: 1.2),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Formula $_currentFormulaNumber Complete',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You solved it in ${game.attempts.length} ${game.attempts.length == 1 ? "try" : "tries"}!',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isDialogOpen = false);
              _startNewRound();
            },
            child: Text('Next Formula', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
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

  void _showLossDialog(NerdleGame game) {
    if (_lossShownForCurrentFormula) return;
    _lossShownForCurrentFormula = true;
    setState(() => _isDialogOpen = true);
    final themeColor = AppTheme.primaryOrange;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(child: Text('GAME OVER', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: _dialogTitleFontSize))),
        content: Text(
          'The equation was:\n\n${game.targetEquation}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
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
}

class _NerdleView extends StatelessWidget {
  final VoidCallback onNewGame;
  final void Function(NerdleGame game) onShowCongrats;
  final void Function(NerdleGame game) onShowLoss;

  const _NerdleView({
    required this.onNewGame,
    required this.onShowCongrats,
    required this.onShowLoss,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NerdleGame>(
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
                        _EquationRow(
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
            _NerdleKeyboard(game: game),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _EquationRow extends StatelessWidget {
  final String attempt;
  final int attemptIndex;
  final NerdleGame game;

  const _EquationRow({required this.attempt, required this.attemptIndex, required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < game.equationLength; i++)
            _CharBox(
              char: i < attempt.length ? attempt[i] : '',
              status: attemptIndex < game.attempts.length
                  ? game.getCharStatus(attemptIndex, i)
                  : CharStatus.unknown,
            ),
        ],
      ),
    );
  }
}

class _CharBox extends StatelessWidget {
  final String char;
  final CharStatus status;

  const _CharBox({required this.char, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    List<BoxShadow> shadows = [];

    switch (status) {
      case CharStatus.correct:
        backgroundColor = AppColors.correctGreen;
        borderColor = AppColors.correctGreen;
        textColor = Colors.white;
        shadows = [BoxShadow(color: AppColors.correctGreen.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)];
        break;
      case CharStatus.present:
        backgroundColor = AppColors.presentYellow;
        borderColor = AppColors.presentYellow;
        textColor = Colors.white;
        shadows = [BoxShadow(color: AppColors.presentYellow.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)];
        break;
      case CharStatus.absent:
        backgroundColor = AppColors.absentGray;
        borderColor = AppColors.absentGray;
        textColor = Colors.white;
        break;
      case CharStatus.unknown:
        backgroundColor = AppTheme.backgroundColor;
        borderColor = Colors.white;
        textColor = Colors.white;
        break;
    }

    return Container(
      width: 42,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: status == CharStatus.unknown
            ? Border.all(color: borderColor, width: 2)
            : null,
        borderRadius: BorderRadius.circular(6),
        boxShadow: shadows,
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0),
        ),
      ),
    );
  }
}

class _NerdleKeyboard extends StatelessWidget {
  final NerdleGame game;

  const _NerdleKeyboard({required this.game});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3', '+', '-'],
      ['4', '5', '6', 'x', '÷'],
      ['7', '8', '9', '0', '='],
      ['⌫', 'ENTER'],
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
                return _NerdleKey(
                  char: key,
                  onTap: () {
                    if (key == 'ENTER') {
                      final success = game.submitGuess();
                      if (!success && game.currentGuess.length == game.equationLength) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid equation!'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else if (key == '⌫') {
                      game.removeCharacter();
                    } else {
                      game.addCharacter(key);
                    }
                  },
                  status: key.length == 1 && key != '⌫' ? game.getKeyboardCharStatus(key) : CharStatus.unknown,
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NerdleKey extends StatelessWidget {
  final String char;
  final VoidCallback onTap;
  final CharStatus status;

  const _NerdleKey({required this.char, required this.onTap, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    List<BoxShadow> shadows = [];

    switch (status) {
      case CharStatus.correct:
        backgroundColor = AppColors.correctGreen;
        textColor = Colors.white;
        shadows = [BoxShadow(color: AppColors.correctGreen.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)];
        break;
      case CharStatus.present:
        backgroundColor = AppColors.presentYellow;
        textColor = Colors.white;
        shadows = [BoxShadow(color: AppColors.presentYellow.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)];
        break;
      case CharStatus.absent:
        backgroundColor = AppColors.absentGray;
        textColor = Colors.white;
        break;
      case CharStatus.unknown:
        backgroundColor = const Color(0xFF2A2A2A);
        textColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: char.length > 1 ? 64 : 60,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: status == CharStatus.unknown ? AppTheme.primaryOrange.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
          boxShadow: shadows,
        ),
        child: Center(
          child: Text(
            char,
            style: TextStyle(
              fontSize: char.length > 1 ? 12 : 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: char.length > 1 ? 0.5 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
