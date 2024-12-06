import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_tape_store/Pages/Utils/Constants.dart';
import 'package:video_tape_store/Services/AuthService.dart';
import 'package:video_tape_store/models/VideoTape.dart';
import 'package:video_tape_store/pages/Admin/AdminPage.dart';

class AdminVideoListPage extends StatefulWidget {
  const AdminVideoListPage({super.key});

  @override
  State<AdminVideoListPage> createState() => _AdminVideoListPageState();
}

class _AdminVideoListPageState extends State<AdminVideoListPage> {
  bool _isLoading = false;
  final _searchController = TextEditingController();
  String _selectedGenre = 'All';
  List<VideoTape> _videoTapes = [];

  List<VideoTape> get _filteredTapes {
    return _videoTapes.where((tape) {
      final matchesSearch = tape.title.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesGenre =
          _selectedGenre == 'All' || tape.genreName == _selectedGenre;
      return matchesSearch && matchesGenre;
    }).toList();
  }

  Future<void> _fetchVideoTapes() async {
    setState(() => _isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/videotapes");
    try {
      print("Fetching video tapes...");
      final response = await http.get(url);
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _videoTapes = data.map((video) => VideoTape.fromJson(video)).toList();
        });
        print("Video tapes loaded: ${_videoTapes.length}");
      } else {
        throw Exception("Failed to load video tapes");
      }
    } catch (e) {
      print("Error fetching video tapes: $e");
      _showErrorSnackBar('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVideoTape(VideoTape tape) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${tape.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isLoading = true);

      try {
        final token = await AuthService.getToken();
        if (token == null) {
          throw Exception("No authentication token");
        }

        final response = await http.delete(
          Uri.parse("http://localhost:3000/api/videotapes/${tape.id}"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _videoTapes.remove(tape);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video tape deleted successfully')),
            );
          }
        } else {
          throw Exception("Failed to delete video");
        }
      } catch (e) { 
        _showErrorSnackBar('Failed to delete video tape: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchVideoTapes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        title: const Text(
          'Manage Video Tapes',
          style: AppTextStyles.headingMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditVideoPage(),
                ),
              );
              print("Returned from add page, fetching data...");
              await _fetchVideoTapes();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            color: AppColors.surfaceColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search video tapes...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusSmall,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.marginMedium),
                DropdownButton<String>(
                  value: _selectedGenre,
                  items: [
                    'All',
                    ...VideoGenre.values.map((e) => e.displayName),
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGenre = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTapes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppDimensions.paddingMedium),
                        itemCount: _filteredTapes.length,
                        itemBuilder: (context, index) {
                          final tape = _filteredTapes[index];
                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: AppDimensions.marginMedium,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(
                                  AppDimensions.paddingMedium),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.borderRadiusSmall),
                                child: Image.network(
                                  tape.imageUrls.first,
                                  width: 60,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                tape.title,
                                style: AppTextStyles.bodyMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${tape.price.toStringAsFixed(2)}',
                                    style: AppTextStyles.priceText,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppDimensions.borderRadiusSmall,
                                          ),
                                        ),
                                        child: Text(
                                          tape.genreName,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stock: ${tape.stockQuantity}',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddEditVideoPage(tape: tape),
                                        ),
                                      );
                                      print(
                                          "Returned from edit page, fetching data...");
                                      await _fetchVideoTapes();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: AppColors.errorColor,
                                    onPressed: () => _deleteVideoTape(tape),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_creation_outlined,
            size: AppDimensions.iconSizeLarge * 2,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: AppDimensions.marginLarge),
          const Text(
            'No video tapes found',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppDimensions.marginMedium),
          Text(
            _searchController.text.isEmpty
                ? 'Add some video tapes to get started'
                : 'Try adjusting your search or filters',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTapeCard(VideoTape tape) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.marginMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingMedium),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          child: Image.network(
            tape.imageUrls.first,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          tape.title,
          style: AppTextStyles.bodyMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '\$${tape.price.toStringAsFixed(2)}',
              style: AppTextStyles.priceText,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusSmall,
                    ),
                  ),
                  child: Text(
                    tape.genreName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Stock: ${tape.stockQuantity}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditVideoPage(tape: tape),
                  ),
                ).then((_) => _fetchVideoTapes());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: AppColors.errorColor,
              onPressed: () => _deleteVideoTape(tape),
            ),
          ],
        ),
      ),
    );
  }
}
