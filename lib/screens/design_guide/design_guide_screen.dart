import 'package:flutter/material.dart';
import '../../shared/themes/app_theme.dart';

enum _DesignSection {
  colorPalette,
  windowStandard,
  typography,
  gameplayScene,
  flutterIcons,
}

/// Design System Guide - Internal reference for UI consistency
class DesignGuideScreen extends StatefulWidget {
  const DesignGuideScreen({super.key});

  @override
  State<DesignGuideScreen> createState() => _DesignGuideScreenState();
}

class _DesignGuideScreenState extends State<DesignGuideScreen> {
  _DesignSection _section = _DesignSection.colorPalette;

  static const _sectionLabels = {
    _DesignSection.colorPalette: '🎨 Color Palette',
    _DesignSection.windowStandard: '📋 Window Standard',
    _DesignSection.typography: '📝 Typography',
    _DesignSection.gameplayScene: '🎮 Gameplay Scene',
    _DesignSection.flutterIcons: '🔣 Flutter Icons (Material)',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text(
          'DESIGN SYSTEM GUIDE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DropdownButton<_DesignSection>(
              value: _section,
              isExpanded: true,
              dropdownColor: AppTheme.backgroundColor,
              style: const TextStyle(
                color: AppTheme.primaryCyan,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              underline: Container(
                height: 2,
                color: AppTheme.primaryCyan,
              ),
              items: _DesignSection.values.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(_sectionLabels[s]!),
                );
              }).toList(),
              onChanged: (s) {
                if (s != null) setState(() => _section = s);
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildSectionContent(),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_section) {
      case _DesignSection.colorPalette:
        return _buildColorPalette();
      case _DesignSection.windowStandard:
        return _buildWindowStandard();
      case _DesignSection.typography:
        return _buildTypography();
      case _DesignSection.gameplayScene:
        return _buildGameplayScene();
      case _DesignSection.flutterIcons:
        return _buildFlutterIcons();
    }
  }

  /// All available Flutter Material Icons (subset) — display name and IconData for reference.
  static final List<(IconData icon, String name)> _flutterIconsList = [
    (Icons.replay, 'replay'),
    (Icons.refresh, 'refresh'),
    (Icons.restart_alt, 'restart_alt'),
    (Icons.leaderboard, 'leaderboard'),
    (Icons.emoji_events, 'emoji_events'),
    (Icons.military_tech, 'military_tech'),
    (Icons.shop, 'shop'),
    (Icons.shopping_cart, 'shopping_cart'),
    (Icons.store, 'store'),
    (Icons.menu_book, 'menu_book'),
    (Icons.rule, 'rule'),
    (Icons.info_outline, 'info_outline'),
    (Icons.logout, 'logout'),
    (Icons.exit_to_app, 'exit_to_app'),
    (Icons.close, 'close'),
    (Icons.check, 'check'),
    (Icons.add, 'add'),
    (Icons.remove, 'remove'),
    (Icons.arrow_back, 'arrow_back'),
    (Icons.arrow_forward, 'arrow_forward'),
    (Icons.arrow_back_ios, 'arrow_back_ios'),
    (Icons.arrow_forward_ios, 'arrow_forward_ios'),
    (Icons.home, 'home'),
    (Icons.settings, 'settings'),
    (Icons.palette, 'palette'),
    (Icons.games, 'games'),
    (Icons.sports_esports, 'sports_esports'),
    (Icons.celebration, 'celebration'),
    (Icons.star, 'star'),
    (Icons.stars, 'stars'),
    (Icons.favorite, 'favorite'),
    (Icons.favorite_border, 'favorite_border'),
    (Icons.thumb_up, 'thumb_up'),
    (Icons.thumb_down, 'thumb_down'),
    (Icons.lightbulb, 'lightbulb'),
    (Icons.lightbulb_outline, 'lightbulb_outline'),
    (Icons.help_outline, 'help_outline'),
    (Icons.error_outline, 'error_outline'),
    (Icons.warning, 'warning'),
    (Icons.info, 'info'),
    (Icons.person, 'person'),
    (Icons.people, 'people'),
    (Icons.pets, 'pets'),
    (Icons.image, 'image'),
    (Icons.photo_camera, 'photo_camera'),
    (Icons.music_note, 'music_note'),
    (Icons.volume_up, 'volume_up'),
    (Icons.volume_off, 'volume_off'),
    (Icons.notifications, 'notifications'),
    (Icons.email, 'email'),
    (Icons.lock, 'lock'),
    (Icons.lock_open, 'lock_open'),
    (Icons.visibility, 'visibility'),
    (Icons.visibility_off, 'visibility_off'),
    (Icons.search, 'search'),
    (Icons.filter_list, 'filter_list'),
    (Icons.sort, 'sort'),
    (Icons.more_vert, 'more_vert'),
    (Icons.more_horiz, 'more_horiz'),
    (Icons.expand_more, 'expand_more'),
    (Icons.expand_less, 'expand_less'),
    (Icons.play_arrow, 'play_arrow'),
    (Icons.pause, 'pause'),
    (Icons.stop, 'stop'),
    (Icons.skip_next, 'skip_next'),
    (Icons.skip_previous, 'skip_previous'),
    (Icons.repeat, 'repeat'),
    (Icons.shuffle, 'shuffle'),
    (Icons.timer, 'timer'),
    (Icons.timer_off, 'timer_off'),
    (Icons.schedule, 'schedule'),
    (Icons.calendar_today, 'calendar_today'),
    (Icons.edit, 'edit'),
    (Icons.delete, 'delete'),
    (Icons.save, 'save'),
    (Icons.download, 'download'),
    (Icons.upload, 'upload'),
    (Icons.share, 'share'),
    (Icons.link, 'link'),
    (Icons.code, 'code'),
    (Icons.bug_report, 'bug_report'),
    (Icons.build, 'build'),
    (Icons.dashboard, 'dashboard'),
    (Icons.grid_view, 'grid_view'),
    (Icons.list, 'list'),
    (Icons.view_list, 'view_list'),
    (Icons.fullscreen, 'fullscreen'),
    (Icons.fullscreen_exit, 'fullscreen_exit'),
    (Icons.zoom_in, 'zoom_in'),
    (Icons.zoom_out, 'zoom_out'),
    (Icons.sentiment_satisfied, 'sentiment_satisfied'),
    (Icons.sentiment_dissatisfied, 'sentiment_dissatisfied'),
    (Icons.sentiment_neutral, 'sentiment_neutral'),
    (Icons.thumb_up_outlined, 'thumb_up_outlined'),
    (Icons.workspace_premium, 'workspace_premium'),
    (Icons.card_giftcard, 'card_giftcard'),
    (Icons.redeem, 'redeem'),
    (Icons.local_offer, 'local_offer'),
    (Icons.loyalty, 'loyalty'),
    (Icons.vibration, 'vibration'),
    (Icons.rate_review, 'rate_review'),
    (Icons.backspace, 'backspace'),
    (Icons.keyboard_return, 'keyboard_return'),
    (Icons.check_circle, 'check_circle'),
    (Icons.cancel, 'cancel'),
    (Icons.radio_button_checked, 'radio_button_checked'),
    (Icons.radio_button_unchecked, 'radio_button_unchecked'),
    (Icons.check_box, 'check_box'),
    (Icons.check_box_outlined, 'check_box_outlined'),
  ];

  Widget _buildFlutterIcons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flutter Material Icons (subset)',
          style: TextStyle(
            color: AppTheme.primaryCyan,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Icons from Material Icons — use Icons.name in code.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _flutterIconsList.length,
          itemBuilder: (context, index) {
            final entry = _flutterIconsList[index];
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.5), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(entry.$1, color: AppTheme.primaryCyan, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    entry.$2,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static const _resetRed = Color(0xFFFF2222);

  /// Gameplay palette: 10 colors, order 1,3,9,8,5,2,6,4,10,7; names drop "Neon"; pale = 2nd column
  static const _gameplayOrder = [1, 3, 9, 8, 5, 2, 6, 4, 10, 7]; // 1-based indices
  static const _gameplayColorsRaw = [
    {'name': 'Neon Red', 'color': Color(0xFFFF0040), 'hex': '#FF0040'},
    {'name': 'Neon Pink', 'color': Color(0xFFFF3399), 'hex': '#FF3399'},
    {'name': 'Neon Cyan', 'color': AppColors.primary, 'hex': '#00D9FF'},
    {'name': 'Purple', 'color': Color(0xFF9900FF), 'hex': '#9900FF'},
    {'name': 'Neon Orange', 'color': AppTheme.primaryOrange, 'hex': '#FF6600'},
    {'name': 'Turquoise', 'color': Color(0xFF00FFAA), 'hex': '#00FFAA'},
    {'name': 'Neon Magenta', 'color': AppColors.accent, 'hex': '#FF00FF'},
    {'name': 'Yellow', 'color': Color(0xFFFFFF00), 'hex': '#FFFF00'},
    {'name': 'Neon Green', 'color': AppTheme.neonGreen, 'hex': '#00FF41'},
    {'name': 'Neon Blue', 'color': Color(0xFF0080FF), 'hex': '#0080FF'},
  ];
  static const _gameplayPaleRaw = [
    {'color': Color(0xFFFF99AA), 'hex': '#FF99AA'},
    {'color': Color(0xFFFF99DD), 'hex': '#FF99DD'},
    {'color': Color(0xFF99EEFF), 'hex': '#99EEFF'},
    {'color': Color(0xFFDD99FF), 'hex': '#DD99FF'},
    {'color': Color(0xFFFFBB88), 'hex': '#FFBB88'},
    {'color': Color(0xFF99FFDD), 'hex': '#99FFDD'},
    {'color': Color(0xFFFF99FF), 'hex': '#FF99FF'},
    {'color': Color(0xFFFFFF99), 'hex': '#FFFF99'},
    {'color': Color(0xFF99FFAA), 'hex': '#99FFAA'},
    {'color': Color(0xFF99CCFF), 'hex': '#99CCFF'},
  ];

  // Order: Background, then 2nd–6th match bottom buttons left to right (Restart, Rank, Shop, Rules, Leave)
  static const _interfaceColors = [
    {'name': 'Background', 'color': AppTheme.backgroundColor, 'hex': '#000000'},
    {'name': 'Cyan (Restart)', 'color': AppTheme.primaryCyan, 'hex': '#00D9FF'},
    {'name': 'Green (Rank)', 'color': AppTheme.neonGreen, 'hex': '#00FF41'},
    {'name': 'Yellow (Shop)', 'color': const Color(0xFFCCFF00), 'hex': '#CCFF00'},
    {'name': 'Orange (Rules)', 'color': AppTheme.primaryOrange, 'hex': '#FF6600'},
    {'name': 'Magenta (Leave)', 'color': AppTheme.primaryMagenta, 'hex': '#FF00FF'},
    {'name': 'Red', 'color': _resetRed, 'hex': '#FF2222'},
    {'name': 'Pink', 'color': const Color(0xFFFF4081), 'hex': '#FF4081'},
    {'name': 'Gold', 'color': const Color(0xFFFFD700), 'hex': '#FFD700'},
    {'name': 'Blue', 'color': const Color(0xFF00B0FF), 'hex': '#00B0FF'},
    {'name': 'Mint', 'color': const Color(0xFF00FFCC), 'hex': '#00FFCC'},
    {'name': 'Peach', 'color': const Color(0xFFFFCC80), 'hex': '#FFCC80'},
    {'name': 'Ruby', 'color': const Color(0xFFFF5252), 'hex': '#FF5252'},
    {'name': 'Lavender', 'color': const Color(0xFFCCACF9), 'hex': '#CCACF9'},
    {'name': 'Blush', 'color': const Color(0xFFF7C1E9), 'hex': '#F7C1E9'},
    {'name': 'Coral', 'color': const Color(0xFFFD8A74), 'hex': '#FD8A74'},
  ];

  /// Gameplay palette: reordered by [1,3,9,8,5,2,6,4,10,7]; display name drops "Neon"
  List<Map<String, Object>> get _gameplayColors => _gameplayOrder.map((oneBased) {
    final raw = _gameplayColorsRaw[oneBased - 1];
    final name = (raw['name'] as String).replaceFirst(RegExp(r'^Neon '), '');
    return <String, Object>{'name': name, 'color': raw['color'] as Color, 'hex': raw['hex'] as String};
  }).toList();

  List<Map<String, Object>> get _gameplayPale => _gameplayOrder.map((oneBased) {
    final raw = _gameplayPaleRaw[oneBased - 1];
    return <String, Object>{'color': raw['color'] as Color, 'hex': raw['hex'] as String};
  }).toList();

  /// Gameplay palette flattened to 20 rows: 10 main colors then 10 pale (name = "Pale {mainName}").
  List<Map<String, Object>> get _gameplayColorsFlat {
    final main = _gameplayColors;
    final pale = _gameplayPale;
    return [
      ...main.map((m) => <String, Object>{'name': m['name'] as String, 'color': m['color'] as Color, 'hex': m['hex'] as String}),
      ...List.generate(10, (i) => <String, Object>{
        'name': 'Pale ${main[i]['name'] as String}',
        'color': pale[i]['color'] as Color,
        'hex': pale[i]['hex'] as String,
      }),
    ];
  }

  Widget _buildColorPalette() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Interface',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        _buildInterfaceColorTable(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Gameplay palette',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        _buildGameplayColorTable(),
      ],
    );
  }

  /// Interface table with extra column: block styled like gameplay bottom button (black inner, theme border, glow).
  Widget _buildInterfaceColorTable() {
    const double blockSize = 44;
    const double radius = 12;
    const double glowBlur = 10;
    const double glowSpread = 1;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.2),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.white24, width: 1),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Color name', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Solid', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Glow', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Button style', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ..._interfaceColors.map((r) {
          final c = r['color'] as Color;
          final name = r['name'] as String;
          final hex = r['hex'] as String;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(hex, style: TextStyle(color: AppTheme.textGrey, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Container(
                    width: blockSize,
                    height: blockSize,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24, width: 1)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Container(
                    width: blockSize,
                    height: blockSize,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24, width: 1),
                      boxShadow: [BoxShadow(color: c.withOpacity(0.78), blurRadius: 22, spreadRadius: 5)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: c.withOpacity(0.5),
                          blurRadius: glowBlur,
                          spreadRadius: glowSpread,
                        ),
                      ],
                    ),
                    child: Container(
                      width: blockSize,
                      height: blockSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: c, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildColorTable(List<Map<String, Object>> rows, {required bool showIndex}) {
    return Table(
      columnWidths: showIndex
          ? const {
              0: FlexColumnWidth(0.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            }
          : const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.white24, width: 1),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08)),
          children: [
            if (showIndex)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Text('Idx', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Color', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Solid', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Glow', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...rows.map((r) {
          final c = r['color'] as Color;
          final name = r['name'] as String;
          final hex = r['hex'] as String;
          final idx = r['index'];
          return TableRow(
            children: [
              if (showIndex && idx != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Text('${idx as int}', style: TextStyle(color: AppTheme.textGrey, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(hex, style: TextStyle(color: AppTheme.textGrey, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24, width: 1)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24, width: 1),
                      boxShadow: [BoxShadow(color: c.withOpacity(0.78), blurRadius: 22, spreadRadius: 5)],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Jenga block style — same as lib/games/jenga/screens/game_screen.dart (gradient + border + shadow)
  Widget _gameplayBlockJengaStyle(Color color, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.6),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.8),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildGameplayColorTable() {
    final flat = _gameplayColorsFlat;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(0.9),
        2: FlexColumnWidth(0.9),
        3: FlexColumnWidth(0.9),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.white24, width: 1),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Color name', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Solid', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Glow', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Jenga', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...flat.map((r) {
          final name = r['name'] as String;
          final hex = r['hex'] as String;
          final c = r['color'] as Color;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(hex, style: TextStyle(color: AppTheme.textGrey, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24, width: 1)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24, width: 1),
                      boxShadow: [BoxShadow(color: c.withOpacity(0.78), blurRadius: 22, spreadRadius: 5)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Center(child: _gameplayBlockJengaStyle(c)),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTypography() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Typography',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'App bar and main titles use Arial. Body and UI use the system default sans-serif '
            '(Roboto on Android, San Francisco on iOS). Code and hex values use monospace.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          const Text(
            'TITLE TEXT',
            style: TextStyle(
              fontFamily: 'Arial',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '28px, Weight 900, Spacing 2.0 — Font: Arial',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          
          const Divider(height: 32, color: Colors.white24),
          
          const Text(
            'Heading Text',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '20px, Bold, Spacing 1.5 — Font: System default',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          
          const Divider(height: 32, color: Colors.white24),
          
          const Text(
            'Body Text',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '16px, Normal, Spacing 0.5 — Font: System default',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          
          const Divider(height: 32, color: Colors.white24),
          
          Text(
            'Secondary Text',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 0.3,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '14px, Grey, Spacing 0.3 — Font: System default',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          
          const Divider(height: 32, color: Colors.white24),
          
          Text(
            '#00D9FF',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: AppTheme.primaryCyan,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '14px, Monospace — for hex codes and code',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Standard UI for in-game windows (AlertDialog / modal).
  Widget _buildWindowStandard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Window Standard',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'All in-game modal windows (dialogs) follow this structure for consistency.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildNote('Structure', 'Use AlertDialog (or Dialog with same styling).'),
          _buildNote('Background', 'Pure black (#000000).'),
          _buildNote('Shape', 'RoundedRectangleBorder: borderRadius 12, border 2px in theme color (e.g. cyan, magenta, green per context).'),
          _buildNote('Title', 'Centered, theme color, bold, ~16pt. No image in title; use text only (e.g. "Congratulations", "Leave game?").'),
          _buildNote('Content', 'White font (Colors.white). Constrain width when needed (e.g. SizedBox width 320) for scrollable content.'),
          _buildNote('Actions', 'Bottom row: TextButton(s) in theme color, bold, ~14pt. Use sentence case for labels (e.g. "Next Level", "Share to Friends").'),
          _buildNote('Buttons', 'Primary actions (OK, Yes, Next Level) and secondary (Cancel, No, Share to Friends) as TextButtons; same theme color.'),
          const SizedBox(height: 24),
          Text(
            'Example',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryCyan, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Center(
                    child: Text(
                      'Congratulations',
                      style: TextStyle(
                        color: AppTheme.primaryCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Level 5 Complete',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'Content area: white font, optional image or list.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Share to Friends',
                          style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Next Level',
                          style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gameplay scene: top panel (game-dependent) and bottom panel (generic) buttons.
  Widget _buildGameplayScene() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gameplay Scene',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'During gameplay, the screen has a top panel (game-dependent buttons) and a bottom panel (generic buttons). Both use the same visual style; only the set of actions and colors differ.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            'Top panel — Game-dependent buttons',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actions that vary by game (e.g. Number Link: Skin, Hint, Shuffle). Each button has its own theme color for quick recognition. Use distinct neon colors from the interface palette (e.g. Ruby for Skin, Gold for Hint, Mint for Shuffle). Same style as bottom: black fill, 2px theme-color border, outer glow (blur ~10, spread ~1), icon above label, 11pt bold font in theme color, letter spacing 0.3. Buttons dim (onPressed null) when a dialog is open.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Bottom panel — Generic buttons',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fixed set across games, left to right: Restart, Rank (leaderboard), Shop, Rules, Leave. Colors follow the interface palette: Restart = cyan (#00D9FF), Rank = green (#00FF41), Shop = yellow (#CCFF00), Rules = orange (#FF6600), Leave = magenta (#FF00FF). Style: black background, 2px border in theme color, outer glow (theme color ~50% opacity, blur 10, spread 1), rounded corners 12px, height ~42px. Layout: icon on top, label below; font 11pt bold, theme color, letter spacing 0.3. Short labels (e.g. "Restart", "Rank", "Shop", "Rules", "Leave"). Buttons dim when a dialog is open.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildNote('Color criteria', 'One color per action. Use neon/distinct colors from the interface palette so each button is recognizable at a glance.'),
          _buildNote('Font', '11pt bold, theme color, letter spacing 0.3. Labels sentence case or short (e.g. "Hint", "Next Level").'),
          _buildNote('Glow', 'BoxShadow: theme color at ~50% opacity, blurRadius 10, spreadRadius 1.'),
        ],
      ),
    );
  }

  Widget _buildNote(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(
                      color: AppTheme.textGrey,
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
