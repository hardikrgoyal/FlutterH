import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/maintenance/services/list_management_service.dart';

class CentralizedDropdown extends ConsumerWidget {
  final String listTypeCode;
  final String? selectedValue;
  final String labelText;
  final String? hintText;
  final Icon? prefixIcon;
  final bool isRequired;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const CentralizedDropdown({
    super.key,
    required this.listTypeCode,
    this.selectedValue,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.isRequired = false,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listDataAsync = ref.watch(listDataProvider(listTypeCode));

    return listDataAsync.when(
      loading: () => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: 'Loading...',
          prefixIcon: prefixIcon,
          border: const OutlineInputBorder(),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stackTrace) => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: 'Error loading options',
          prefixIcon: prefixIcon,
          border: const OutlineInputBorder(),
          errorText: 'Failed to load options',
        ),
        items: const [],
        onChanged: null,
      ),
      data: (listData) {
        if (listData == null) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: labelText,
              hintText: 'No options available',
              prefixIcon: prefixIcon,
              border: const OutlineInputBorder(),
            ),
            items: const [],
            onChanged: null,
          );
        }

        final items = listData.items.map((item) {
          return DropdownMenuItem<String>(
            value: item.code ?? item.name,
            child: Text(item.name),
          );
        }).toList();

        // Add "Add New..." option if enabled
        if (enabled) {
          items.add(
            const DropdownMenuItem<String>(
              value: 'Add New...',
              child: Text('Add New...'),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            labelText: isRequired ? '$labelText *' : labelText,
            hintText: hintText,
            prefixIcon: prefixIcon,
            border: const OutlineInputBorder(),
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator ?? (isRequired ? (value) {
            if (value == null || value.isEmpty || value == 'Add New...') {
              return 'Please select $labelText';
            }
            return null;
          } : null),
        );
      },
    );
  }
}

class CentralizedDropdownWithAddNew extends ConsumerStatefulWidget {
  final String listTypeCode;
  final String? selectedValue;
  final String labelText;
  final String? hintText;
  final Icon? prefixIcon;
  final bool isRequired;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool canAddNew;

  const CentralizedDropdownWithAddNew({
    super.key,
    required this.listTypeCode,
    this.selectedValue,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.isRequired = false,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.canAddNew = true,
  });

  @override
  ConsumerState<CentralizedDropdownWithAddNew> createState() => _CentralizedDropdownWithAddNewState();
}

class _CentralizedDropdownWithAddNewState extends ConsumerState<CentralizedDropdownWithAddNew> {
  bool _showAddNewField = false;
  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listDataAsync = ref.watch(listDataProvider(widget.listTypeCode));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        listDataAsync.when(
          loading: () => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: 'Loading...',
              prefixIcon: widget.prefixIcon,
              border: const OutlineInputBorder(),
            ),
            items: const [],
            onChanged: null,
          ),
          error: (error, stackTrace) => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: 'Error loading options',
              prefixIcon: widget.prefixIcon,
              border: const OutlineInputBorder(),
              errorText: 'Failed to load options',
            ),
            items: const [],
            onChanged: null,
          ),
          data: (listData) {
            if (listData == null) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: 'No options available',
                  prefixIcon: widget.prefixIcon,
                  border: const OutlineInputBorder(),
                ),
                items: const [],
                onChanged: null,
              );
            }

            final items = listData.items.map((item) {
              return DropdownMenuItem<String>(
                value: item.code ?? item.name,
                child: Text(item.name),
              );
            }).toList();

            // Add "Add New..." option if enabled
            if (widget.enabled && widget.canAddNew) {
              items.add(
                const DropdownMenuItem<String>(
                  value: 'Add New...',
                  child: Text('Add New...'),
                ),
              );
            }

            return DropdownButtonFormField<String>(
              value: widget.selectedValue,
              decoration: InputDecoration(
                labelText: widget.isRequired ? '${widget.labelText} *' : widget.labelText,
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon,
                border: const OutlineInputBorder(),
              ),
              items: items,
              onChanged: widget.enabled ? (value) {
                if (value == 'Add New...') {
                  setState(() {
                    _showAddNewField = true;
                  });
                } else {
                  setState(() {
                    _showAddNewField = false;
                    _newItemController.clear();
                  });
                  widget.onChanged(value);
                }
              } : null,
              validator: widget.validator ?? (widget.isRequired ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select ${widget.labelText}';
                }
                if (value == 'Add New...' && _newItemController.text.trim().isEmpty) {
                  return 'Please enter a new ${widget.labelText}';
                }
                return null;
              } : null),
            );
          },
        ),
        
        // Add new item field
        if (_showAddNewField) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _newItemController,
            decoration: InputDecoration(
              labelText: 'New ${widget.labelText}',
              hintText: 'Enter new ${widget.labelText}',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      final newValue = _newItemController.text.trim();
                      if (newValue.isNotEmpty) {
                        // Add the new item to the list
                        final listData = await ref.read(listDataProvider(widget.listTypeCode).future);
                        if (listData != null) {
                          final newItem = ListItem(
                            id: 0,
                            listType: listData.items.first.id, // This needs to be the list type ID
                            name: newValue,
                            code: newValue.toLowerCase().replaceAll(' ', '_'),
                            sortOrder: listData.items.length + 1,
                            isActive: true,
                            createdBy: 0,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          final success = await ref.read(listManagementProvider.notifier).addListItem(newItem);
                          if (success) {
                            // Clear cache and refresh
                            ref.read(listManagementProvider.notifier).clearCacheForListType(widget.listTypeCode);
                            ref.invalidate(listDataProvider(widget.listTypeCode));
                            
                            setState(() {
                              _showAddNewField = false;
                            });
                            widget.onChanged(newItem.code ?? newItem.name);
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('New item added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to add new item'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _showAddNewField = false;
                        _newItemController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
            onFieldSubmitted: (value) {
              // Same logic as the check button
            },
          ),
        ],
      ],
    );
  }
} 