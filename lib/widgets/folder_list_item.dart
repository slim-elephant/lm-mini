import 'dart:io';

import 'package:flutter/material.dart';
import '../models/chat_folder.dart';
import '../utils/image_picker_helper.dart';

class FolderListItem extends StatelessWidget {
  final ChatFolder folder;
  final int conversationCount;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FolderListItem({
    super.key,
    required this.folder,
    required this.conversationCount,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = folder.parsedColor ?? scheme.primaryContainer;
    final imagePath = folder.imagePath != null
        ? ImagePickerHelper.resolveImagePathSync(folder.imagePath!)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: isSelected ? 1 : 0,
      color: isSelected
          ? color.withValues(alpha: 0.18)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? color.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: imagePath == null ? color : null,
            borderRadius: BorderRadius.circular(12),
            image: imagePath != null
                ? DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imagePath == null
              ? Icon(
                  Icons.folder_rounded,
                  color: color.computeLuminance() > 0.55
                      ? Colors.black87
                      : Colors.white,
                )
              : null,
        ),
        title: Text(
          folder.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$conversationCount conversation${conversationCount != 1 ? 's' : ''}',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              size: 20,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: scheme.onSurfaceVariant,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
