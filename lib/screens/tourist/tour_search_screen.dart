import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tour_provider.dart';
import '../../models/tour.dart';
import '../../widgets/common/loading_overlay.dart';

class TourSearchScreen extends StatefulWidget {
  const TourSearchScreen({super.key});

  @override
  State<TourSearchScreen> createState() => _TourSearchScreenState();
}

class _TourSearchScreenState extends State<TourSearchScreen> {
  final _joinCodeController = TextEditingController();
  Tour? _foundTour;
  bool _isSearching = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Tours'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Consumer<TourProvider>(
        builder: (context, tourProvider, child) {
          return LoadingOverlay(
            isLoading: _isSearching,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Join Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ask your tour provider for the unique join code',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _joinCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Join Code',
                      hintText: 'e.g., TOUR123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _searchTour(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _searchTour,
                      icon: const Icon(Icons.search),
                      label: const Text('Search Tour'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (tourProvider.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(244, 67, 54, 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color.fromRGBO(244, 67, 54, 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tourProvider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],    
              if (_foundTour != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Tour Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundTour!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_foundTour!.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _foundTour!.description!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(_foundTour!.status),
                                  size: 16,
                                  color: _getStatusColor(_foundTour!.status),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _foundTour!.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(_foundTour!.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (_foundTour!.startDate != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Start: ${_formatDate(_foundTour!.startDate!)}',
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _registerForTour(_foundTour!.joinCode),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Register for Tour'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _searchTour() async {
    if (_joinCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a join code')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _foundTour = null;
    });

    final tourProvider = Provider.of<TourProvider>(context, listen: false);
    final tour = await tourProvider.searchTourByJoinCode(_joinCodeController.text.trim());
    
    setState(() {
      _isSearching = false;
      _foundTour = tour;
    });
  }

  void _registerForTour(String joinCode) async {
    final tourProvider = Provider.of<TourProvider>(context, listen: false);
    final success = await tourProvider.registerForTour(joinCode);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully registered for tour!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Icons.check_circle;
      case 'draft':
        return Icons.edit;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}