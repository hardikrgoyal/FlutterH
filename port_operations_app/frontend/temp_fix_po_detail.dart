  Widget _buildLinkManagementRow(bool canManage) {
    final hasLink = (_purchaseOrder.linkedWoId != null) || ((_purchaseOrder.linkedWoIds ?? []).isNotEmpty);
    final ids = <String>[];
    if (_purchaseOrder.linkedWoId != null) ids.add(_purchaseOrder.linkedWoId!);
    if (_purchaseOrder.linkedWoIds != null) ids.addAll(_purchaseOrder.linkedWoIds!);

    final wosAsync = ref.watch(workOrdersProvider('open'));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Linked WOs', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              if (canManage)
                wosAsync.when(
                  data: (wos) {
                    // Count all open WOs (since one WO can have multiple POs)
                    final availableCount = wos.where((w) => w.status == 'open').length;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                          child: Text('$availableCount', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          onPressed: _onLinkWo,
                          icon: const Icon(Icons.link, size: 16),
                          label: const Text('Link WO'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                      ],
                    );
                  },
                  loading: () => TextButton.icon(
                    onPressed: _onLinkWo,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Link WO'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                  error: (_, __) => TextButton.icon(
                    onPressed: _onLinkWo,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Link WO'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
            ],
          ),
