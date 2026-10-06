import 'dart:ui' show ImageFilter;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/buttons.dart';
import '../../widgets/fields.dart';
import '../../widgets/scaffold.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/itext.dart';

PillTone ticketTone(TicketStatus s) => switch (s) {
  TicketStatus.open => PillTone.submitted,
  TicketStatus.progress => PillTone.reviewed,
  TicketStatus.resolved => PillTone.accepted,
};

/// Help — maps 1:1 to native `HelpView`.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _category = 'All';
  String _query = '';

  List<Ticket> _filtered(AppState state) {
    final q = _query.toLowerCase();
    return state.tickets.where((t) {
      final inCategory = _category == 'All' || t.category == _category;
      final matches =
          q.isEmpty ||
          t.subject.toLowerCase().contains(q) ||
          t.id.toLowerCase().contains(q) ||
          t.messages.any((m) => m.text.toLowerCase().contains(q));
      return inCategory && matches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tickets = _filtered(state);
    return ScreenScroll(
      bottom: Spacing.tabBarClearance,
      children: [
        Text('TULONG · HELP', style: Typo.eyebrow).rise(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IText('How can we help, ${state.profile?.firstName ?? 'Maria'}?', style: Typo.h1(36)),
        ).rise(1),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: TahananTextField(
            placeholder: 'Search your tickets',
            value: _query,
            onChanged: (v) => setState(() => _query = v),
            leadingIcon: TIcon.search,
          ),
        ).rise(2),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Pressable(
            onTap: () => context.go(const Screen(ScreenKind.newTicket)),
            semanticLabel: 'Start a new ticket',
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(26),
              child: ColoredBox(
                color: Palette.yellow,
                child: Stack(
                  children: [
                    Positioned(
                      right: -24,
                      bottom: -50,
                      width: 120,
                      height: 140,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: Palette.white(0.25),
                          shape: const ArchBorder(bottomRadius: 0),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
                            child: const TIconView(TIcon.plus, size: 24, color: Palette.yellow),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Start a new ticket', style: Typo.outfit(19, Typo.semibold, Palette.ink)),
                                const SizedBox(height: 2),
                                Opacity(
                                  opacity: 0.78,
                                  child: Text(
                                    'A Homeful agent replies right in the chat.',
                                    style: Typo.manrope(13, Typo.semibold, Palette.ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Native HStack spacing before its trailing Spacer.
                          const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).rise(3),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: EdgeScroller(
            height: 40,
            children: [
              for (final c in ['All', ...state.ticketCategories])
                FilterChipButton(
                  c,
                  selected: _category == c,
                  selectedFill: Palette.text,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
        ).rise(4),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('My tickets', style: Typo.sectionTitle())),
              Text(
                '${tickets.length} ${tickets.length == 1 ? 'ticket' : 'tickets'}',
                style: Typo.manrope(13, Typo.bold, Palette.subtle),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              for (final (i, t) in tickets.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                Pressable(
                  onTap: () => context.go(Screen.ticket(t.id)),
                  semanticLabel: '${t.subject}, ${t.status.label}',
                  child: TicketCard(ticket: t),
                ),
              ],
            ],
          ),
        ).rise(5),
      ],
    );
  }
}

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${ticket.id} · ${ticket.category}', style: Typo.mono(12, Typo.medium, Palette.subtle)),
                ),
                StatusPill(ticket.status.label, tone: ticketTone(ticket.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text(ticket.subject, style: Typo.manrope(15, Typo.extrabold, Palette.text)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.manrope(13, Typo.regular, Palette.muted),
                  ),
                ),
                const SizedBox(width: 12),
                Text(ticket.time, style: Typo.manrope(12, Typo.regular, Palette.placeholder)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: Ticket chat

class TicketChatScreen extends StatefulWidget {
  const TicketChatScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = -1;
  bool _lastTyping = false;

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(end, duration: const Duration(milliseconds: 350), curve: Motion.easeInOut);
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  void _send() {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    _draft.clear();
    context.read<AppState>().send(text, to: widget.ticketId);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.ticket(widget.ticketId);
    final typing = state.agentTyping.contains(widget.ticketId);
    final count = t?.messages.length ?? 0;
    if (count != _lastCount || typing != _lastTyping) {
      _toBottom(animate: _lastCount >= 0);
      _lastCount = count;
      _lastTyping = typing;
    }
    final insets = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return ColoredBox(
      color: Palette.night,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(16, insets.top + 136 - 54, 16, 12),
                    children: [
                      for (final (i, m) in (t?.messages ?? const <TicketMessage>[]).indexed) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _message(context, m),
                      ],
                      if (typing) ...[const SizedBox(height: 10), _typing()],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + (keyboard > 0 ? keyboard : insets.bottom)),
                  child: _composer(),
                ),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, top: 0, child: _header(t, insets.top)),
        ],
      ),
    );
  }

  Widget _header(Ticket? t, double top) {
    final shape = RoundedRectangleBorder(
      borderRadius: cornerBox(0, 0, 26, 26),
      side: BorderSide(color: Palette.white(0.09)),
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: ShapeDecoration(color: const Color(0xEB0D1C38), shape: shape),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, top + 4, 16, 14),
            child: Row(
              children: [
                BackCircleButton(onTap: () => context.go(Screen.help)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t?.subject ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Typo.manrope(15, Typo.extrabold, Palette.text),
                      ),
                      const SizedBox(height: 2),
                      Text('${t?.id ?? ''} · ${t?.category ?? ''}', style: Typo.mono(11, Typo.medium, Palette.subtle)),
                    ],
                  ),
                ),
                if (t != null) ...[const SizedBox(width: 12), StatusPill(t.status.label, tone: ticketTone(t.status))],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _bubbleIn = BorderSide(color: Color(0x17FFFFFF));

  Widget _message(BuildContext context, TicketMessage m) {
    final body = Typo.manrope(14, Typo.regular, Palette.text).copyWith(height: 1.36 + 5 / 14);
    switch (m.kind) {
      case MessageKind.sys:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: ShapeDecoration(color: Palette.white(0.06), shape: const StadiumBorder()),
              child: Text(m.text, style: Typo.manrope(11, Typo.extrabold, Palette.subtle)),
            ),
          ).fadeIn(),
        );
      case MessageKind.them:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const AgentAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(m.who ?? '', style: Typo.manrope(11, Typo.bold, Palette.subtle)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Palette.white(0.055),
                      borderRadius: cornerBox(20, 20, 20, 6),
                      border: const Border.fromBorderSide(_bubbleIn),
                    ),
                    child: Text(m.text, style: body),
                  ),
                  if (m.attachment) _attachment(context),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: Text(m.time ?? '', style: Typo.manrope(10, Typo.regular, Palette.placeholder)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ).rise();
      case MessageKind.me:
        return Row(
          children: [
            const SizedBox(width: 60),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(color: Palette.blue, borderRadius: cornerBox(20, 20, 6, 20)),
                    child: Text(m.text, style: body.copyWith(color: const Color(0xFFFFFFFF))),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(m.time ?? '', style: Typo.manrope(10, Typo.regular, Palette.placeholder)),
                  ),
                ],
              ),
            ),
          ],
        ).rise();
    }
  }

  Widget _attachment(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Pressable(
      onTap: () {
        context.read<AppState>().update(() => context.read<AppState>().applicationTab = ApplicationTab.requirements);
        context.go(Screen.application);
      },
      semanticLabel: 'Latest payslips (3 months)',
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(
              icon: TIcon.document,
              tint: Palette.yellow,
              background: Palette.yellow.o(0.16),
              size: 34,
              radius: 10,
              iconSize: 18,
            ),
            const SizedBox(width: 10),
            Flexible(child: Text('Latest payslips (3 months)', style: Typo.manrope(13, Typo.extrabold, Palette.text))),
            const SizedBox(width: 10),
            const TIconView(TIcon.arrowRight, size: 18, color: Palette.yellow),
          ],
        ),
      ),
    ),
  );

  Widget _typing() => Semantics(
    label: 'Support is typing',
    child: Row(
      children: [
        const AgentAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Palette.white(0.055),
            borderRadius: cornerBox(20, 20, 20, 6),
            border: const Border.fromBorderSide(_bubbleIn),
          ),
          child: const TypingDots(),
        ),
      ],
    ).fadeIn(),
  );

  Widget _composer() => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 58,
          child: Glass(
            radius: 29,
            fill: const Color(0xEB0D1C38),
            blur: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  // TODO: API — chat attachments (upload to ticket)
                  IconCircleButton(
                    TIcon.paperclip,
                    label: 'Attach file',
                    background: const Color(0x00000000),
                    noBorder: true,
                    onTap: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _draft,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: Typo.manrope(15, Typo.regular, Palette.text),
                      cursorColor: Palette.yellow,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Write a message…',
                        hintStyle: Typo.manrope(15, Typo.regular, Palette.placeholder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Pressable(
        onTap: _send,
        semanticLabel: 'Send',
        child: Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.yellow,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Palette.yellow.o(0.45), blurRadius: 12, offset: const Offset(0, 12))],
          ),
          child: const TIconView(TIcon.send, size: 22, color: Palette.ink),
        ),
      ),
    ],
  );
}

/// Three dots bouncing in sequence (tdotA 1.2 s, .15 s stagger).
class TypingDots extends StatelessWidget {
  const TypingDots({super.key});

  @override
  Widget build(BuildContext context) => Timeline(
    builder: (_, t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Builder(
            builder: (_) {
              final p = (((t - i * 0.15) % 1.2) + 1.2) % 1.2 / 1.2;
              final k = p < 0.4
                  ? Motion.easeInOut.transform(p / 0.4)
                  : (p < 0.8 ? 1 - Motion.easeInOut.transform((p - 0.4) / 0.4) : 0.0);
              return Opacity(
                opacity: mix(0.3, 1, k),
                child: Transform.translate(
                  offset: Offset(0, -3 * k),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Palette.label, shape: BoxShape.circle),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    ),
  );
}

// MARK: New ticket

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  String _category = 'Documents';
  String _subject = '';
  final _message = TextEditingController();
  final _messageFocus = FocusNode();
  String? _attachment;

  @override
  void initState() {
    super.initState();
    _messageFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = (await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
    )).firstOrNull;
    // TODO: API — upload the attachment with the ticket
    if (f != null) setState(() => _attachment = f.name);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hint = Typo.manrope(16, Typo.regular, Palette.placeholder);
    return ColoredBox(
      color: Palette.night,
      child: Stack(
        children: [
          ScreenScroll(
            bottom: Spacing.tabBarClearance,
            children: [
              ScreenHeader(title: 'New ticket', onBack: () => context.go(Screen.help)),
              const Padding(padding: EdgeInsets.only(top: 26, bottom: 8), child: FieldLabel('Category')).rise(1),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in state.ticketCategories)
                    FilterChipButton(c, selected: _category == c, onTap: () => setState(() => _category = c)),
                ],
              ).rise(1),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TahananTextField(
                  label: 'Subject',
                  placeholder: 'e.g. Payslip upload keeps failing',
                  value: _subject,
                  onChanged: (v) => _subject = v,
                ),
              ).rise(2),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Describe the issue'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _messageFocus.requestFocus,
                      child: FieldChrome(
                        focused: _messageFocus.hasFocus,
                        height: null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 120),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: TextField(
                              controller: _message,
                              focusNode: _messageFocus,
                              minLines: 1,
                              maxLines: null,
                              style: Typo.manrope(16, Typo.regular, Palette.text).copyWith(height: 1.37 + 8 / 16),
                              cursorColor: Palette.yellow,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Tell us what happened. Include your unit code if it’s about a booking.',
                                hintMaxLines: 4,
                                hintStyle: hint.copyWith(height: 1.37 + 8 / 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).rise(3),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Pressable(
                  onTap: _pick,
                  semanticLabel: _attachment ?? 'Attach a photo or file',
                  child: SizedBox(
                    height: 76,
                    child: DashedBorder(
                      radius: 20,
                      color: Palette.white(0.22),
                      width: 1.5,
                      dash: 6,
                      gap: 4,
                      fill: Palette.white(0.03),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TIconView(TIcon.paperclip, color: Palette.soft),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _attachment ?? 'Attach a photo or file',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Typo.manrope(14, Typo.extrabold, Palette.soft),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).rise(4),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomCTABar(
              child: PrimaryButton(
                'Submit ticket',
                icon: TIcon.send,
                iconSize: 18,
                onTap: () {
                  final id = state.createTicket(category: _category, subject: _subject, message: _message.text);
                  context.go(Screen.ticket(id));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
