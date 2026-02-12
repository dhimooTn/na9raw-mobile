import 'package:flutter/material.dart';
import '../models/course_material_model.dart';
import 'course_material_dialogs.dart';

// Supprimez les définitions de CourseMaterial et MaterialType d'ici
// Le reste du code reste identique

class CourseMaterialsSection extends StatelessWidget {
  final TextEditingController thumbnailController;
  final List<CourseMaterial> courseMaterials;
  final ValueChanged<CourseMaterial> onAddMaterial;
  final ValueChanged<int> onRemoveMaterial;
  final ValueChanged<String> onSetThumbnail;

  const CourseMaterialsSection({
    super.key,
    required this.thumbnailController,
    required this.courseMaterials,
    required this.onAddMaterial,
    required this.onRemoveMaterial,
    required this.onSetThumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Materials',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: MaterialActionButton(
                icon: Icons.image,
                label: 'Add Thumbnail',
                onTap: () => _showAddThumbnailDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MaterialActionButton(
                icon: Icons.upload_file,
                label: 'Add File URL',
                onTap: () => _showAddFileDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MaterialActionButton(
                icon: Icons.videocam,
                label: 'Add Video URL',
                onTap: () => _showAddVideoDialog(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (thumbnailController.text.isNotEmpty)
          ThumbnailPreview(thumbnailUrl: thumbnailController.text),

        const SizedBox(height: 20),

        if (courseMaterials.isNotEmpty)
          MaterialsList(
            courseMaterials: courseMaterials,
            onRemoveMaterial: onRemoveMaterial,
          ),
      ],
    );
  }

  void _showAddThumbnailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddThumbnailDialog(
        onThumbnailAdded: onSetThumbnail,
      ),
    );
  }

  void _showAddFileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddFileDialog(
        onFileAdded: onAddMaterial,
      ),
    );
  }

  void _showAddVideoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddVideoDialog(
        onVideoAdded: onAddMaterial,
      ),
    );
  }
}

class MaterialActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MaterialActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ThumbnailPreview extends StatelessWidget {
  final String thumbnailUrl;

  const ThumbnailPreview({
    super.key,
    required this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Thumbnail:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Invalid Image URL'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class MaterialsList extends StatelessWidget {
  final List<CourseMaterial> courseMaterials;
  final ValueChanged<int> onRemoveMaterial;

  const MaterialsList({
    super.key,
    required this.courseMaterials,
    required this.onRemoveMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Added Materials (${courseMaterials.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...courseMaterials.asMap().entries.map((entry) {
          int idx = entry.key;
          CourseMaterial material = entry.value;
          return MaterialItem(
            material: material,
            onDelete: () => onRemoveMaterial(idx),
          );
        }).toList(),
      ],
    );
  }
}

class MaterialItem extends StatelessWidget {
  final CourseMaterial material;
  final VoidCallback onDelete;

  const MaterialItem({
    super.key,
    required this.material,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: material.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            material.icon,
            color: material.color,
            size: 24,
          ),
        ),
        title: Text(
          material.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          material.url.isNotEmpty ? material.url : material.size,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete,
            color: Colors.red.withOpacity(0.6),
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}