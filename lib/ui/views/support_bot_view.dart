import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:busmen_panama/core/viewmodels/home_viewmodel.dart';
import 'package:busmen_panama/core/services/language_service.dart';
import 'package:busmen_panama/ui/views/lost_found_view.dart';
import 'package:busmen_panama/ui/views/password_view.dart';
import 'package:busmen_panama/ui/views/schedules_view.dart';

class SupportBotView extends StatefulWidget {
  const SupportBotView({super.key});

  @override
  State<SupportBotView> createState() => _SupportBotViewState();
}

// ─── Data model for a chat message ───────────────────────────────────────────

class _BotMessage {
  final String text;
  final bool isBot;
  final List<_BotOption>? options;

  const _BotMessage({required this.text, required this.isBot, this.options});
}

class _BotOption {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback action;

  const _BotOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.action,
  });
}

// ─── State ────────────────────────────────────────────────────────────────────

class _SupportBotViewState extends State<SupportBotView> {
  final ScrollController _scrollController = ScrollController();
  final List<_BotMessage> _messages = [];
  bool _showMainMenu = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial bot greeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBotGreeting();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotGreeting() async {
    final localization = context.read<LanguageService>();
    await _addBotMessage(
      localization.getString('bot_greeting'),
    );
    _showOptions();
  }

  Future<void> _addBotMessage(String text, {List<_BotOption>? options, bool withDelay = true}) async {
  if (withDelay) {
    setState(() {
      _isTyping = true;
      _showMainMenu = false;
    });
    _scrollToBottom();
    
    final delay = Duration(milliseconds: 600 + (text.length * 10).clamp(0, 1500));
    await Future.delayed(delay);
    
    if (!mounted) return;
    
    setState(() {
      _isTyping = false;
      _messages.add(_BotMessage(text: text, isBot: true, options: options));
    });
  } else {
    setState(() {
      _messages.add(_BotMessage(text: text, isBot: true, options: options));
    });
  }
  _scrollToBottom();
}

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_BotMessage(text: text, isBot: false));
      _showMainMenu = false;
    });
    _scrollToBottom();
  }

  void _showOptions() {
    setState(() => _showMainMenu = true);
    _scrollToBottom();
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _showMainMenu = false;
    });
    _addBotGreeting();
  }

  // ─── FAQ Handlers ──────────────────────────────────────────────────────────

  void _handleSchedule() async {
    final localization = context.read<LanguageService>();
    _addUserMessage(localization.getString('bot_schedule_q'));
    await _addBotMessage(
      localization.getString('bot_schedule_ans'),
      options: [
        _BotOption(
          label: localization.getString('bot_view_schedules'),
          icon: Icons.schedule_rounded,
          color: const Color(0xFF064DC3),
          action: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesView()));
          },
        ),
        _BotOption(
          label: localization.getString('bot_back_menu'),
          icon: Icons.arrow_back_rounded,
          color: Colors.grey,
          action: () async {
            _addUserMessage(localization.getString('bot_user_back_menu'));
            await _addBotMessage(localization.getString('bot_more_help'));
            _showOptions();
          },
        ),
      ],
    );
  }

  void _handleLostFound() async{
    final localization = context.read<LanguageService>();
    _addUserMessage(localization.getString('bot_lost_found_q'));
    await _addBotMessage(
      localization.getString('bot_lost_found_ans'),
      options: [
        _BotOption(
          label: localization.getString('bot_report_item'),
          icon: Icons.search_rounded,
          color: const Color(0xFFE67E22),
          action: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundView()));
          },
        ),
        _BotOption(
          label: localization.getString('bot_back_menu'),
          icon: Icons.arrow_back_rounded,
          color: Colors.grey,
          action: () async {
            _addUserMessage(localization.getString('bot_user_back_menu'));
            await _addBotMessage(localization.getString('bot_more_help'));
            _showOptions();
          },
        ),
      ],
    );
  }

  void _handlePasswordChange() async {
    final localization = context.read<LanguageService>();
    _addUserMessage(localization.getString('bot_password_q'));
    await _addBotMessage(
      localization.getString('bot_password_ans'),
      options: [
        _BotOption(
          label: localization.getString('bot_change_pass'),
          icon: Icons.lock_outline_rounded,
          color: const Color(0xFF8E44AD),
          action: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordView()));
          },
        ),
        _BotOption(
          label: localization.getString('bot_back_menu'),
          icon: Icons.arrow_back_rounded,
          color: Colors.grey,
          action: () async {
            _addUserMessage(localization.getString('bot_user_back_menu'));
            await _addBotMessage(localization.getString('bot_more_help'));
            _showOptions();
          },
        ),
      ],
    );
  }

  void _handleCallSupport() async{
    final localization = context.read<LanguageService>();
    _addUserMessage(localization.getString('bot_call_support_q'));
    await _addBotMessage(
      localization.getString('bot_call_support_ans'),
      options: [
        _BotOption(
          label: localization.getString('bot_call_now'),
          icon: Icons.phone_rounded,
          color: const Color(0xFF27AE60),
          action: () {
            final homeVM = context.read<HomeViewModel>();
            homeVM.makeMonitoringCall();
          },
        ),
        _BotOption(
          label: localization.getString('cancel_btn'),
          icon: Icons.close_rounded,
          color: Colors.grey,
          action: () async {
            _addUserMessage(localization.getString('bot_cancel_call'));
            await _addBotMessage(localization.getString('bot_understood_help'));
            _showOptions();
          },
        ),
      ],
    );
  }

  void _handleUnitDirection() async{
    final localization = context.read<LanguageService>();
    _addUserMessage(localization.getString('bot_unit_dir_q'));
    await _addBotMessage(
      localization.getString('bot_unit_dir_ans'),
      options: [
        _BotOption(
          label: localization.getString('bot_back_menu'),
          icon: Icons.arrow_back_rounded,
          color: const Color(0xFF064DC3),
          action: () async {
            _addUserMessage(localization.getString('bot_user_back_menu'));
            await _addBotMessage(localization.getString('bot_more_help'));
            _showOptions();
          },
        ),
      ],
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LanguageService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // Main menu options
    final List<_BotOption> menuOptions = [
      _BotOption(
        label: localization.getString('bot_schedule_q'),
        icon: Icons.schedule_outlined,
        color: const Color(0xFF064DC3),
        action: _handleSchedule,
      ),
      _BotOption(
        label: localization.getString('bot_lost_found_q'),
        icon: Icons.search_outlined,
        color: const Color(0xFFE67E22),
        action: _handleLostFound,
      ),
      _BotOption(
        label: localization.getString('bot_password_q'),
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFF8E44AD),
        action: _handlePasswordChange,
      ),
      _BotOption(
        label: localization.getString('bot_call_support_q'),
        icon: Icons.phone_rounded,
        color: const Color(0xFF27AE60),
        action: _handleCallSupport,
      ),
      _BotOption(
        label: localization.getString('bot_unit_dir_q'),
        icon: Icons.directions_bus_rounded,
        color: const Color(0xFF34495E),
        action: _handleUnitDirection,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          localization.getString('monitoring_center').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF053E9E) : const Color(0xFF064DC3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetChat,
            tooltip: localization.getString('bot_reset_chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark, cardColor);
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark, cardColor);
              },
            ),
          ),

          // Main menu options (shown when bot is waiting for user selection)
          if (_showMainMenu)
            _buildMainMenu(menuOptions, isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_BotMessage msg, bool isDark, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF064DC3),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isBot
                        ? cardColor
                        : const Color(0xFF064DC3),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(msg.isBot ? 4 : 18),
                      bottomRight: Radius.circular(msg.isBot ? 18 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isBot
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                // Inline option buttons after bot message
                if (msg.isBot && msg.options != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: msg.options!.map((opt) => _buildOptionChip(opt)).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (!msg.isBot) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person_rounded, color: Colors.grey[600], size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF064DC3),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return _TypingDot(index: index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip(_BotOption option) {
    return Material(
      color: option.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: option.action,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: option.color.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 14, color: option.color),
              const SizedBox(width: 6),
              Text(option.label, style: TextStyle(color: option.color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu(List<_BotOption> options, bool isDark) {
    final localization = context.watch<LanguageService>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            localization.getString('bot_menu_title'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: opt.action,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: opt.color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: opt.color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: opt.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(opt.icon, color: opt.color, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: opt.color),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _TypingDot extends StatefulWidget {
  final int index;
  const _TypingDot({required this.index});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF064DC3).withOpacity(0.3 + (0.7 * _animation.value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
