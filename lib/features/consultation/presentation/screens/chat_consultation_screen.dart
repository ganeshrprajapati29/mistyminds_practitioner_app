import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../data/models/talk_request.dart';
import '../../../../data/realtime/realtime_service.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../state/providers.dart';
import '../consultation_args.dart';
import '../widgets/consultation_widgets.dart';

/// Chat consultation. Messages go through the session's thread on the server
/// (`/practitioner/sessions/:id/messages`), which the client app shares; the
/// thread is refreshed every couple of seconds while the chat is open.
class ChatConsultationScreen extends ConsumerStatefulWidget {
  const ChatConsultationScreen({super.key, required this.args});

  final ConsultationArgs args;

  @override
  ConsumerState<ChatConsultationScreen> createState() =>
      _ChatConsultationScreenState();
}

class _ChatConsultationScreenState extends ConsumerState<ChatConsultationScreen>
    with SessionClock<ChatConsultationScreen> {
  static const List<String> _quickReplies = <String>[
    'I’m here with you.',
    'Take your time.',
    'Can you tell me more?',
    'That sounds really hard.',
  ];

  /// Messages normally arrive instantly over the socket; this re-read is a
  /// safety net for when the socket drops.
  static const Duration _refreshEvery = Duration(seconds: 6);

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _typing = false;
  bool _sending = false;
  Timer? _refresh;
  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];
  DateTime _lastTypingSent = DateTime(2000);

  String? get _sessionId => widget.args.sessionId;
  RealtimeService? get _realtime => ref.read(realtimeProvider);

  @override
  void initState() {
    super.initState();
    startClock();
    _input.addListener(_onInput);
    _load();
    _refresh = Timer.periodic(_refreshEvery, (_) => _load());
    _listenLive();
  }

  @override
  void dispose() {
    _refresh?.cancel();
    for (final StreamSubscription<Object?> s in _subs) {
      unawaited(s.cancel());
    }
    _stopTyping();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Live messages, the client's typing indicator, and the client ending the
  /// session — all pushed over the socket.
  void _listenLive() {
    final RealtimeService? live = _realtime;
    final String? conversationId = widget.args.conversationId;
    if (live == null) return;
    if (conversationId != null) live.joinConversation(conversationId);

    _subs.add(
      live
          .on('chat:message')
          .where((RealtimeEvent e) => e.data['sessionId'] == _sessionId)
          .listen((RealtimeEvent e) {
            final ChatMessage m = ChatMessage.fromJson(
              (e.data['message'] as Map<dynamic, dynamic>)
                  .cast<String, dynamic>(),
            );
            if (!mounted || _messages.any((ChatMessage x) => x.id == m.id)) {
              return;
            }
            setState(() {
              _messages = <ChatMessage>[..._messages, m];
              _typing = false;
            });
            _scrollToEnd();
          }),
    );
    for (final String name in <String>['typing:start', 'typing:stop']) {
      _subs.add(
        live
            .on(name)
            .where(
              (RealtimeEvent e) => e.data['conversationId'] == conversationId,
            )
            .listen((_) {
              if (mounted) setState(() => _typing = name == 'typing:start');
            }),
      );
    }
    final StreamSubscription<RealtimeEvent>? ended = onClientEnded(
      ref,
      widget.args,
      () => finishEndedByClient(
        context,
        ref,
        args: widget.args,
        elapsed: elapsed,
      ),
    );
    if (ended != null) _subs.add(ended);
  }

  /// Tells the client "your psychologist is typing", at most every 3 seconds.
  void _onInput() {
    setState(() {});
    final String? conversationId = widget.args.conversationId;
    if (conversationId == null || _input.text.trim().isEmpty) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastTypingSent) < const Duration(seconds: 3)) return;
    _lastTypingSent = now;
    _realtime?.emit('typing:start', conversationId);
  }

  void _stopTyping() {
    final String? conversationId = widget.args.conversationId;
    if (conversationId == null) return;
    _lastTypingSent = DateTime(2000);
    _realtime?.emit('typing:stop', conversationId);
  }

  /// Pulls the thread; only rebuilds when something actually changed.
  Future<void> _load() async {
    final String? id = _sessionId;
    if (id == null) return;
    try {
      final ChatSnapshot chat = await ref
          .read(repositoryProvider)
          .fetchChat(id);
      if (!mounted) return;
      final bool grew = chat.messages.length != _messages.length;
      // With a socket, typing comes live from the client; without one (the
      // socket was down) the snapshot carries it.
      final bool typing = _realtime == null ? chat.clientTyping : _typing;
      if (grew || typing != _typing) {
        setState(() {
          _messages = chat.messages;
          _typing = typing;
        });
        if (grew) _scrollToEnd();
      }
    } catch (_) {
      // Keep the conversation on screen; the next refresh will retry.
    }
  }

  Future<void> _send([String? preset]) async {
    final String text = (preset ?? _input.text).trim();
    final String? id = _sessionId;
    if (text.isEmpty || id == null || _sending) return;
    setState(() => _sending = true);
    _stopTyping();
    final bool ok = await AppFeedback.guard(context, () async {
      final ChatMessage sent = await ref
          .read(repositoryProvider)
          .sendChatMessage(id, text);
      if (!mounted) return;
      setState(() {
        _messages = <ChatMessage>[
          ..._messages.where((ChatMessage m) => m.id != sent.id),
          sent,
        ];
      });
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok && preset == null) _input.clear();
    });
    if (ok) _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ConsultationArgs a = widget.args;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) endConsultation(context, ref, args: a, elapsed: elapsed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _Header(
                args: a,
                elapsed: elapsed,
                onEnd: () =>
                    endConsultation(context, ref, args: a, elapsed: elapsed),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.md,
                    AppSizes.lg,
                    AppSizes.md,
                  ),
                  children: <Widget>[
                    const MistyInfoNote(
                      text:
                          'This conversation is private and encrypted. The '
                          'client sees only your name and title.',
                      icon: Icons.lock_outline_rounded,
                      center: true,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Center(
                      child: Text(
                        'Session started · ${Fmt.time(DateTime.now().subtract(elapsed))}',
                        style: AppTypography.caption,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    for (final ChatMessage m in _messages) _Bubble(message: m),
                    if (_typing) const _TypingBubble(),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickReplies.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSizes.sm),
                  itemBuilder: (_, int i) => Center(
                    child: MistyChip(
                      label: _quickReplies[i],
                      onTap: () => _send(_quickReplies[i]),
                    ),
                  ),
                ),
              ),
              _Composer(
                controller: _input,
                canSend: _input.text.trim().isNotEmpty && !_sending,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.args,
    required this.elapsed,
    required this.onEnd,
  });

  final ConsultationArgs args;
  final Duration elapsed;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.sm,
        AppSizes.lg,
        AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: <Widget>[
          MistyProfileAvatar(
            name: args.clientName,
            photoUrl: args.photoUrl,
            anonymous: args.anonymous,
            size: 46,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  args.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingSmall,
                ),
                Row(
                  children: <Widget>[
                    const PresenceDot(color: AppColors.online, size: 7),
                    Text(
                      '${args.isTalkNow ? 'Talk Now' : 'Chat'} · ${Fmt.clock(elapsed)}',
                      style: AppTypography.body(
                        12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEnd,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.coralSoft,
              foregroundColor: AppColors.coral,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              shape: const StadiumBorder(),
            ),
            child: const Text('End'),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool me = message.fromMe;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (BuildContext context, double t, Widget? child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: child,
        ),
      ),
      child: Align(
        alignment: me ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.76,
          ),
          margin: const EdgeInsets.only(bottom: AppSizes.sm + 2),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            gradient: me ? AppColors.ctaGradient : null,
            color: me ? null : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(me ? 18 : 4),
              bottomRight: Radius.circular(me ? 4 : 18),
            ),
            boxShadow: me ? null : AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                message.text,
                style: AppTypography.body(
                  14.5,
                  color: me ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.time(message.time),
                style: AppTypography.body(
                  10.5,
                  color: me ? Colors.white70 : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow,
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha:
                          0.25 + 0.6 * (((_c.value * 3 - i) % 3) < 1 ? 1 : 0),
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

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.sm,
        AppSizes.lg,
        AppSizes.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppTypography.body(15),
              decoration: InputDecoration(
                hintText: 'Write a message…',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: canSend ? 1 : 0.45,
            child: Material(
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  onTap: canSend ? onSend : null,
                  child: const SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
