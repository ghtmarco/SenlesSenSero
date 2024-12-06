import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_tape_store/Pages/Utils/Constants.dart';
import 'package:video_tape_store/Services/AuthService.dart';
import 'package:video_tape_store/models/VideoTape.dart';
import 'package:video_tape_store/widgets/TextFIeld.dart';
import 'package:video_tape_store/widgets/Button.dart';

class AddEditVideoPage extends StatefulWidget {
  final VideoTape? tape;

  const AddEditVideoPage({
    super.key,
    this.tape,
  });

  @override
  State<AddEditVideoPage> createState() => _AddEditVideoPageState();
}

class _AddEditVideoPageState extends State<AddEditVideoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final List<String> _imageUrls = [];

  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late final TextEditingController _ratingController;
  String _selectedGenre = VideoGenre.action.displayName;
  int _selectedLevel = 1;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tape?.title);
    _priceController = TextEditingController(
      text: widget.tape?.price.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.tape?.description,
    );
    _stockController = TextEditingController(
      text: widget.tape?.stockQuantity.toString(),
    );

    // Perbaiki format rating
    _ratingController = TextEditingController(
        text: widget.tape?.rating.toStringAsFixed(1) ?? '');

    if (widget.tape != null) {
      _selectedGenre = widget.tape!.genreName;
      _selectedLevel = widget.tape!.level;
      _imageUrls.addAll(widget.tape!.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _saveVideoTape() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception("No authentication token");

      final url = Uri.parse(
          "http://localhost:3000/api/videotapes${widget.tape?.id != null ? "/${widget.tape!.id}" : ""}");

      final rating = double.tryParse(_ratingController.text);
      if (rating == null) throw Exception("Invalid rating value");

      final requestBody = jsonEncode({
        "title": _titleController.text.trim(),
        "price": double.tryParse(_priceController.text) ?? 0.0,
        "description": _descriptionController.text.trim(),
        "genreId": VideoGenre.values
                .firstWhere((e) => e.displayName == _selectedGenre)
                .index +
            1,
        "level": _selectedLevel,
        "stockQuantity": int.tryParse(_stockController.text) ?? 0,
        "rating": double.parse(_ratingController.text),
        "imageUrls": _imageUrls,
      });

      final response = await (widget.tape?.id != null
          ? http.put(url,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json"
              },
              body: requestBody)
          : http.post(url,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json"
              },
              body: requestBody));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Video tape ${widget.tape?.id != null ? 'updated' : 'created'} successfully')),
          );
        }
      } else {
        throw Exception(
            "Failed to ${widget.tape?.id != null ? 'update' : 'create'} video tape");
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (image != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:3000/api/upload'),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );

        final token = await AuthService.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        var response = await http.Response.fromStream(await request.send());

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final fullUrl = 'http://localhost:3000${data['url']}';
          setState(() => _imageUrls.add(fullUrl));
        } else {
          throw Exception('Upload failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Image upload error: $e');
      _showErrorSnackBar('Failed to upload image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        title: Text(
          widget.tape == null ? 'Add Video Tape' : 'Edit Video Tape',
          style: AppTextStyles.headingMedium,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          children: [
            _buildImagesSection(),
            const SizedBox(height: AppDimensions.marginLarge),
            const Text(
              'Basic Information',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            CustomTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Enter video tape title',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            CustomTextField(
              controller: _priceController,
              label: 'Price',
              hint: 'Enter price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Price is required';
                }
                final price = double.tryParse(value!);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            CustomTextField(
              controller: _ratingController,
              label: 'Rating',
              hint: 'Enter rating',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Rating is required';
                }
                final rating = double.tryParse(value!);
                if (rating == null || rating < 0 || rating > 5) {
                  return 'Rating must be between 0-5';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            CustomTextField(
              controller: _stockController,
              label: 'Stock Quantity',
              hint: 'Enter stock quantity',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Stock quantity is required';
                }
                final stock = int.tryParse(value!);
                if (stock == null || stock < 0) {
                  return 'Please enter a valid stock quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedGenre,
                  hint: const Text('Select Genre'),
                  items: VideoGenre.values.map((genre) {
                    return DropdownMenuItem(
                      value: genre.displayName,
                      child: Text(genre.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGenre = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.marginMedium),
            _buildLevelSelection(),
            const SizedBox(height: AppDimensions.marginLarge),
            const Text(
              'Description',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.marginSmall),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter video tape description',
                filled: true,
                fillColor: AppColors.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusSmall),
                  borderSide: const BorderSide(color: AppColors.dividerColor),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Description is required';
                }
                if (value!.length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.marginLarge * 2),
            CustomButton(
              onPressed: _isLoading ? null : _saveVideoTape,
              text: 'Save Video Tape',
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppDimensions.marginMedium),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
            border: Border.all(color: AppColors.dividerColor),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            itemCount: _imageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == _imageUrls.length) {
                return _buildAddImageButton();
              }
              return _buildImageCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: AppDimensions.marginSmall),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: InkWell(
        onTap: _addImage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: AppDimensions.marginSmall),
            Text(
              'Add Image',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: AppDimensions.marginSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        image: DecorationImage(
          image: _imageUrls[index].startsWith('data:image')
              ? MemoryImage(base64Decode(_imageUrls[index].split(',')[1]))
              : NetworkImage(_imageUrls[index]) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          _buildDeleteButton(index),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(int index) {
    return Positioned(
      top: 4,
      right: 4,
      child: InkWell(
        onTap: () => _removeImage(index),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.errorColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Age Rating',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppDimensions.marginSmall),
        Wrap(
          spacing: AppDimensions.marginSmall,
          children: VideoLevel.values.map((level) {
            final isSelected = _selectedLevel == level.value;
            return ChoiceChip(
              label: Text(level.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedLevel = level.value);
                }
              },
              selectedColor: AppColors.primaryColor,
              backgroundColor: AppColors.surfaceColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.primaryTextColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
