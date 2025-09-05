import 'package:flutter/material.dart';
import 'package:leami_mobile/models/review.dart';
import 'package:leami_mobile/providers/auth_provider.dart';
import 'package:leami_mobile/providers/review_provider.dart';
import 'package:leami_mobile/screens/guest_articles_screen.dart';
import 'package:provider/provider.dart';

class GuestReviewScreen extends StatefulWidget {
  final Review? existingReview; // Dodajte ovaj parametar
  final String? successMessage;
  const GuestReviewScreen({Key? key, this.existingReview, this.successMessage})
    : super(key: key);

  @override
  _GuestReviewScreenState createState() => _GuestReviewScreenState();
}

class _GuestReviewScreenState extends State<GuestReviewScreen> {
  int _selectedRating = 0; // Holds the selected rating (1 to 5 stars)
  final TextEditingController _commentController = TextEditingController();
  ReviewProvider? reviewProvider;
  bool _isEditing = false; // Flag da li uređujemo postojeći review

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = widget.successMessage;
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
      }
    });

    // Ako postoji postojeći review, učitajte podatke
    if (widget.existingReview != null) {
      _isEditing = true;
      _selectedRating = widget.existingReview!.rating ?? 0;
      _commentController.text = widget.existingReview!.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Uredi recenziju' : 'Recenzija'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const GuestArticlesScreen(),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Text(
              _isEditing
                  ? 'Ažurirajte svoju ocjenu naše usluge'
                  : 'Kako biste ocijenili našu uslugu?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // Stars rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < _selectedRating ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = index + 1; // Star rating is 1 to 5
                    });
                  },
                );
              }),
            ),

            // Rating text
            if (_selectedRating > 0)
              Center(
                child: Text(
                  _getRatingText(_selectedRating),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Comment section
            const Text(
              'Ostavite komentar (opcionalno)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Unesite komentar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedRating == 0) {
                    // Show a message if no rating is selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Molimo odaberite ocjenu.')),
                    );
                  } else {
                    _submitReview();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Ažuriraj recenziju' : 'Pošaljite recenziju',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Delete button (samo ako uređujemo postojeći review)
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _showDeleteConfirmation();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Obriši recenziju',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Vrlo loše';
      case 2:
        return 'Loše';
      case 3:
        return 'Solidno';
      case 4:
        return 'Dobro';
      case 5:
        return 'Odlično';
      default:
        return '';
    }
  }

  void _submitReview() async {
    try {
      if (_isEditing) {
        // Ažuriranje postojećeg review-a
        final updatedReview = Review(
          reviewId: widget.existingReview!.reviewId,
          reviewerUserId: widget.existingReview!.reviewerUserId,
          rating: _selectedRating,
          comment: _commentController.text.isEmpty
              ? ""
              : _commentController.text,
          createdAt: widget.existingReview!.createdAt,
        );

        await reviewProvider?.update(updatedReview.reviewId!, updatedReview);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recenzija uspješno ažurirana.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Kreiranje novog review-a
        await reviewProvider?.insert(
          Review(
            reviewerUserId: AuthProvider.user!.id,
            // AuthProvider.Id!,
            rating: _selectedRating,
            comment: _commentController.text.isEmpty
                ? ""
                : _commentController.text,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recenzija uspješno poslata.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GuestArticlesScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Obriši recenziju'),
          content: const Text(
            'Da li ste sigurni da želite obrisati svoju recenziju?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Zatvorite dialog
              },
              child: const Text('Otkaži'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Zatvorite dialog
                _deleteReview();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Obriši'),
            ),
          ],
        );
      },
    );
  }

  void _deleteReview() async {
    try {
      if (widget.existingReview?.reviewId != null) {
        await reviewProvider?.delete(widget.existingReview!.reviewId!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recenzija uspješno obrisana.'),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const GuestArticlesScreen(),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška pri brisanju: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
