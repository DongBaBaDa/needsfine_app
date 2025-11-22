import 'package:flutter/material.dart';

// --- [ Dummy Data Model ] ---
class Address {
  String fullAddress;
  String details;
  bool isCurrent;

  Address({required this.fullAddress, required this.details, this.isCurrent = false});
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isEditing = false;

  // Dummy address list
  final List<Address> _addresses = [
    Address(fullAddress: '전남 순천시 성남뒷길 84', details: '전남 순천시 성남뒷길 84 2층 계단기준 정면 오른쪽 안쪽집', isCurrent: true),
    Address(fullAddress: '전남 광양시 공영로 67', details: '전남 광양시 공영로 67 1층'),
    Address(fullAddress: '전북 군산시 수송로 86', details: '전북 군산시 수송로 86 설빙 앞'),
  ];

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _deleteAddress(int index) {
    setState(() {
      // If deleting the currently set address, we might need to set a new default.
      // For now, just remove it. A real app would need more complex logic.
      _addresses.removeAt(index);
      // If no address is current, set the first one as current.
      if (!_addresses.any((a) => a.isCurrent) && _addresses.isNotEmpty) {
        _addresses.first.isCurrent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('주소 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _toggleEditMode,
            child: Text(_isEditing ? '완료' : '편집', style: const TextStyle(color: Colors.black, fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/address-search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('지번, 도로명, 건물명으로 검색', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Find by current location button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/nearby');
              },
              icon: const Icon(Icons.my_location),
              label: const Text('현재 위치로 찾기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 24),

            // Add home address
            InkWell(
              onTap: (){},
              child: const Row(
                children: [
                  Icon(Icons.home_outlined),
                  SizedBox(width: 8),
                  Text('우리집 추가', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const Divider(height: 32),

            // Address List
            Expanded(
              child: ListView.builder(
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  return _buildAddressTile(
                    context: context,
                    address: address,
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile({
    required BuildContext context,
    required Address address,
    required int index,
  }) {
    return ListTile(
      leading: Icon(
        address.isCurrent ? Icons.location_on : Icons.location_on_outlined,
        color: address.isCurrent ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Row(
        children: [
          Flexible(child: Text(address.fullAddress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
          if(address.isCurrent)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Chip(
                label: const Text('현재 설정된 주소', style: TextStyle(fontSize: 10)),
                padding: const EdgeInsets.all(2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
        ],
      ),
      subtitle: Text(address.details, style: const TextStyle(color: Colors.grey)),
      trailing: _isEditing
          ? IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _deleteAddress(index),
            )
          : (address.isCurrent ? const Icon(Icons.check, color: Colors.green) : null),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // TODO: Implement address selection logic for step 3
      },
    );
  }
}
