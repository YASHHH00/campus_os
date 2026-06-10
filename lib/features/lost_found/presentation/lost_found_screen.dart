import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/campus_app_bar.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../data/models/lost_item_model.dart';
import 'bloc/lost_found_bloc.dart';

/// Lost & Found board screen — grid of items with post and claim actions.
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<LostFoundBloc>().add(const LoadItemsRequested());
  }

  void _showPostItemSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Post Lost/Found Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Image picker
                GestureDetector(
                  onTap: () async {
                    final image = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setSheetState(() => selectedImagePath = image.path);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: selectedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              selectedImagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  color: AppColors.textTertiary,
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.textTertiary,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to take photo',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g., Blue Water Bottle',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Any identifying features...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location found/lost',
                    hintText: 'e.g., Main Canteen',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (titleCtrl.text.trim().isNotEmpty &&
                          locationCtrl.text.trim().isNotEmpty) {
                        context.read<LostFoundBloc>().add(PostItemRequested(
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              imagePath: selectedImagePath ?? '',
                              location: locationCtrl.text.trim(),
                            ));
                        Navigator.pop(ctx);
                      } else {
                        ErrorSnackbar.showWarning(
                          context,
                          'Title and location are required.',
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Post Item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CampusAppBar(
        title: 'Lost & Found',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh from server',
            onPressed: () {
              context.read<LostFoundBloc>().add(const RefreshFromSupabase());
            },
          ),
        ],
      ),
      body: BlocConsumer<LostFoundBloc, LostFoundState>(
        listener: (context, state) {
          switch (state) {
            case ItemPostedSuccess():
              ErrorSnackbar.showSuccess(context, 'Item posted successfully!');
            case ItemClaimedSuccess():
              ErrorSnackbar.showSuccess(context, 'Item claimed!');
            case LostFoundError(message: final msg):
              ErrorSnackbar.showError(context, msg);
            default:
              break;
          }
        },
        builder: (context, state) {
          return switch (state) {
            LostFoundLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryPurple),
              ),
            LostFoundLoaded(items: final items) => _buildItemsGrid(items),
            _ => _buildItemsGrid(const []),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostItemSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report Item'),
        heroTag: 'post_lost_item_fab',
      ),
    );
  }

  Widget _buildItemsGrid(List<LostItemModel> items) {
    if (items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No Items Posted',
        subtitle: 'Lost something? Found something? Post it here for your campus.',
        ctaLabel: 'Post an Item',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LostFoundBloc>().add(const RefreshFromSupabase());
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _LostItemCard(item: items[index]),
      ),
    );
  }
}

class _LostItemCard extends StatelessWidget {
  final LostItemModel item;

  const _LostItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.isActive ? "Active" : "Claimed"} lost item: ${item.title}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showItemDetail(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  color: AppColors.surfaceContainerHigh,
                  child: item.imagePath.isNotEmpty &&
                          item.imagePath.startsWith('http')
                      ? Image.network(
                          item.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),

              // Info section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 11, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.location,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppDateUtils.timeAgo(item.createdAt),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.isActive
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.isActive ? 'Active' : 'Claimed',
                              style: TextStyle(
                                color: item.isActive
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.image_rounded,
        color: AppColors.textTertiary,
        size: 36,
      ),
    );
  }

  void _showItemDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (item.description.isNotEmpty) ...[
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    item.location,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    AppDateUtils.fullDateTime(item.createdAt),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (item.isActive && !item.isOwnPost)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context
                          .read<LostFoundBloc>()
                          .add(ClaimItemRequested(item: item));
                    },
                    icon: const Icon(Icons.front_hand_rounded, size: 18),
                    label: const Text('Claim This Item'),
                  ),
                ),
              if (item.isOwnPost)
                const Center(
                  child: Text(
                    'You posted this item',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
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
