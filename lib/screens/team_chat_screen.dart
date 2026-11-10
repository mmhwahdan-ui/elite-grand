import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class TeamChatScreen extends StatefulWidget {
  final String? initialRecipientId; // null or 'all' for group, or specific userId

  const TeamChatScreen({super.key, this.initialRecipientId});

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _currentChannel = 'all'; // 'all' for group, or specific userId
  String _currentChannelName = 'شات الفريق العام (الكل)';
  String? _selectedTag;
  String? _selectedClientName;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipientId != null && widget.initialRecipientId != 'all') {
      _currentChannel = widget.initialRecipientId!;
    }

    // Mark messages as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().markChatAsRead();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<AppProvider>();
    final tag = _selectedTag;
    final clientName = _selectedClientName;

    _textController.clear();
    setState(() {
      _selectedTag = null;
      _selectedClientName = null;
    });

    await provider.sendChatMessage(
      text: text,
      recipientId: _currentChannel,
      recipientName: _currentChannelName,
      tag: tag,
      relatedClientName: clientName,
    );

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentUser = provider.currentUser;
    final users = provider.users;
    final activeClients = provider.activeClients;

    // Filter messages for current channel
    final List<ChatMessageModel> messages;
    if (_currentChannel == 'all') {
      messages = provider.groupChatMessages;
    } else {
      messages = provider.getDirectMessagesWith(_currentChannel);
    }

    // Direct chat target user
    UserModel? otherUser;
    if (_currentChannel != 'all') {
      try {
        otherUser = users.firstWhere((u) => u.id == _currentChannel || u.username == _currentChannel);
      } catch (_) {}
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          titleSpacing: 10,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_rounded, color: AppTheme.accentBright, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentChannel == 'all'
                        ? 'شات الفريق العام (إيليت جراند)'
                        : 'محادثة خاصة: ${otherUser?.displayName ?? _currentChannelName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentBright,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _currentChannel == 'all'
                            ? 'أفراد الشركة (وهدان، شيماء، زيزو)'
                            : (otherUser?.roleTitle ?? 'محادثة مشفرة ولحظية 24/7'),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Switch channel popup menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              tooltip: 'تبديل غرفة المحادثة',
              onSelected: (val) {
                setState(() {
                  _currentChannel = val;
                  if (val == 'all') {
                    _currentChannelName = 'شات الفريق العام (الكل)';
                  } else {
                    final target = users.firstWhere((u) => u.id == val || u.username == val, orElse: () => users.first);
                    _currentChannelName = target.displayName;
                  }
                });
                Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.groups, color: _currentChannel == 'all' ? AppTheme.primary : Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      const Text('👥 شات الفريق العام (الكل)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ...users.where((u) => u.id != currentUser?.id).map((u) {
                  final isSelected = _currentChannel == u.id || _currentChannel == u.username;
                  return PopupMenuItem(
                    value: u.id,
                    child: Row(
                      children: [
                        Icon(Icons.person, color: isSelected ? Colors.teal : Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.displayName, style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            Text(u.roleTitle, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Channel Selector Tabs Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Group Chat Tab
                    _buildChannelTab(
                      id: 'all',
                      label: '👥 شات الفريق العام',
                      subtitle: 'وهدان • شيماء • زيزو',
                      isSelected: _currentChannel == 'all',
                      color: AppTheme.primary,
                      onTap: () {
                        setState(() {
                          _currentChannel = 'all';
                          _currentChannelName = 'شات الفريق العام (الكل)';
                        });
                        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Direct chat tabs for other members
                    ...users.where((u) => u.id != currentUser?.id).map((u) {
                      final isSelected = _currentChannel == u.id || _currentChannel == u.username;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildChannelTab(
                          id: u.id,
                          label: u.displayName,
                          subtitle: u.roleTitle.split(' ').take(2).join(' '),
                          isSelected: isSelected,
                          color: Colors.teal,
                          onTap: () {
                            setState(() {
                              _currentChannel = u.id;
                              _currentChannelName = u.displayName;
                            });
                            Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Messages View
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentChannel == 'all' ? Icons.chat_bubble_outline : Icons.lock_outline,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentChannel == 'all'
                                ? 'لا توجد رسائل سابقة في شات الفريق'
                                : 'ابدأ محادثة خاصة مع ${otherUser?.displayName ?? "الزميل"}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'المحادثات مشفرة وتتم مزامنتها لحظياً 24/7 مع الشركاء',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = currentUser != null &&
                            (msg.senderId == currentUser.id || msg.senderUsername.trim() == currentUser.username.trim());

                        // Check if need date separator
                        bool showDateHeader = false;
                        if (index == 0) {
                          showDateHeader = true;
                        } else {
                          final prevMsg = messages[index - 1];
                          if (!_isSameDay(prevMsg.timestamp, msg.timestamp)) {
                            showDateHeader = true;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDateHeader) _buildDateSeparator(msg.timestamp),
                            _buildMessageBubble(msg, isMe),
                          ],
                        );
                      },
                    ),
            ),

            // Bottom Message Input & Tag Toolbar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fast Tag & Client Reference Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTagFilterChip('🚨 عاجل', 'urgent', Colors.red),
                        const SizedBox(width: 6),
                        _buildTagFilterChip('🕒 وردية', 'shift', Colors.indigo),
                        const SizedBox(width: 6),
                        _buildTagFilterChip('💵 دفعة', 'payment', Colors.green),
                        const SizedBox(width: 6),
                        _buildTagFilterChip('🩺 تمريض', 'nurse', Colors.teal),
                        const SizedBox(width: 6),
                        _buildTagFilterChip('📋 ملاحظة حالة', 'client', Colors.amber.shade800),
                        const SizedBox(width: 8),

                        // Attach Client Mention
                        if (activeClients.isNotEmpty) ...[
                          PopupMenuButton<String>(
                            tooltip: 'إشارة لحالة معينة',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _selectedClientName != null ? Colors.blue.shade100 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedClientName != null ? Colors.blue : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_pin,
                                    size: 14,
                                    color: _selectedClientName != null ? Colors.blue : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedClientName != null ? 'الحالة: $_selectedClientName' : '+ إشارة لحالة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      fontWeight: _selectedClientName != null ? FontWeight.bold : FontWeight.normal,
                                      color: _selectedClientName != null ? Colors.blue : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (_selectedClientName != null) ...[
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => setState(() => _selectedClientName = null),
                                      child: const Icon(Icons.close, size: 12, color: Colors.blue),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            itemBuilder: (ctx) => activeClients.map((cl) {
                              return PopupMenuItem(
                                value: cl.name,
                                child: Text(cl.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                              );
                            }).toList(),
                            onSelected: (clName) {
                              setState(() => _selectedClientName = clName);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Text Field
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSendMessage(),
                            decoration: InputDecoration(
                              hintText: _currentChannel == 'all'
                                  ? 'اكتب رسالة لجميع أفراد الشركة...'
                                  : 'اكتب رسالة خاصة إلى ${otherUser?.displayName ?? _currentChannelName}...',
                              hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send Button
                      ElevatedButton(
                        onPressed: _handleSendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          elevation: 2,
                        ),
                        child: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTab({
    required String id,
    required String label,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    color: isSelected ? color.withOpacity(0.8) : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilterChip(String label, String value, Color color) {
    final isSelected = _selectedTag == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTag = isSelected ? null : value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Cairo',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(now, date);
    final isYesterday = _isSameDay(now.subtract(const Duration(days: 1)), date);

    String label;
    if (isToday) {
      label = 'اليوم';
    } else if (isYesterday) {
      label = 'أمس';
    } else {
      label = DateFormat('EEEE، d MMMM', 'ar').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.grey.shade800, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final formattedTime = timeFormat.format(msg.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78 > 480 ? 480 : MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: msg.tag == 'urgent'
                ? Colors.red.shade400
                : (isMe ? AppTheme.primary : Colors.grey.shade200),
            width: msg.tag == 'urgent' ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender info (for other members)
            if (!isMe) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.accentBright.withOpacity(0.3),
                    child: Text(
                      msg.senderDisplayName.isNotEmpty ? msg.senderDisplayName[0] : 'U',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.senderDisplayName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      msg.senderRole,
                      style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Tag badge if present (e.g. 🚨 عاجل)
            if (msg.tag != null && msg.tagArabic != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withOpacity(0.2) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  msg.tagArabic!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isMe ? Colors.white : Colors.red,
                  ),
                ),
              ),
            ],

            // Mentioned Client if attached
            if (msg.relatedClientName != null && msg.relatedClientName!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withOpacity(0.18) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_pin, size: 12, color: isMe ? Colors.white : Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'بخصوص الحالة: ${msg.relatedClientName}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: isMe ? Colors.white : Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Message Content Text
            SelectableText(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Cairo',
                color: isMe ? Colors.white : const Color(0xFF0F172A),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),

            // Time & Status
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
