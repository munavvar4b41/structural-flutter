import 'package:flutter/material.dart';

import '../../models/notifications.dart';
import '../../services/app_controller.dart';
import '../../services/desktop_api_client.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.notifications,
      builder: (context, _) {
        final count = controller.notifications.unreadCount;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => _openPanel(context),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }

  Future<void> _openPanel(BuildContext context) async {
    try {
      await controller.notifications.refresh();
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await controller.requireLogin();
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NotificationPanel(controller: controller),
    );
  }
}

class _NotificationPanel extends StatefulWidget {
  const _NotificationPanel({required this.controller});

  final AppController controller;

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onTap(NotificationItem item) async {
    try {
      if (item.isUnread) {
        await widget.controller.notifications.markRead(item.id);
      }
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.controller.requireLogin();
        return;
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    if (item.projectId != null && item.projectTaskId != null) {
      widget.controller.openTaskDetail(
        projectId: item.projectId!,
        taskId: item.projectTaskId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = widget.controller.notifications.feed;
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if ((feed?.unreadCount ?? 0) > 0)
                    TextButton(
                      onPressed: () async {
                        try {
                          await widget.controller.notifications.markAllRead();
                        } on DesktopApiException catch (e) {
                          if (e.statusCode == 401) {
                            await widget.controller.requireLogin();
                          }
                        }
                      },
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Unread (${feed?.unreadCount ?? 0})'),
                Tab(text: 'Read (${feed?.readCount ?? 0})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NotificationList(
                    items: feed?.unreadItems ?? [],
                    scrollController: scrollController,
                    emptyLabel: 'No unread notifications',
                    onTap: _onTap,
                  ),
                  _NotificationList(
                    items: feed?.readItems ?? [],
                    scrollController: scrollController,
                    emptyLabel: 'No read notifications',
                    onTap: _onTap,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
          ],
        );
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.scrollController,
    required this.emptyLabel,
    required this.onTap,
  });

  final List<NotificationItem> items;
  final ScrollController scrollController;
  final String emptyLabel;
  final Future<void> Function(NotificationItem item) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.title ?? 'Notification'),
          subtitle: Text(item.projectName ?? ''),
          trailing: item.isUnread
              ? Icon(
                  Icons.circle,
                  size: 10,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () => onTap(item),
        );
      },
    );
  }
}
