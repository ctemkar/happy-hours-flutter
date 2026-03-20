import 'package:flutter/material.dart';
import '../models/business.dart';

class LocationSelector extends StatelessWidget {
  final List<PopularLocation> locations;
  final String selectedLocation;
  final Function(String) onLocationSelected;

  const LocationSelector({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Select Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...locations.map((location) {
            final isSelected = selectedLocation == location.name;
            return ListTile(
              leading: Icon(
                Icons.location_on,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              title: Text(
                location.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                onLocationSelected(location.name);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}