import 'package:flutter/material.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];

  // Dummy search logic
  void _onSearchChanged(String query) {
    setState(() {
      if (query.contains('성남뒷길')) {
        _searchResults = [
          {'title': '전남 순천시 성남뒷길 84', 'subtitle': '전남 순천시 성남뒷길 84'},
        ];
      } else if (query.contains('서울')) {
        _searchResults = [
          {'title': '서울역', 'subtitle': '서울 용산구 청파로 378 서울역'},
          {'title': '1주차장(KTX빌딩주차장)', 'subtitle': ''},
          {'title': '2주차장(공항철도주차장)', 'subtitle': ''},
          {'title': '3주차장(롯데마트주차장)', 'subtitle': ''},
          {'title': '서울아산병원', 'subtitle': '서울 송파구 올림픽로43길 88 서울아산병원'},
          {'title': '정문', 'subtitle': ''},
          {'title': '남문', 'subtitle': ''},
        ];
      } else if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = [
          {'title': "검색 결과가 없습니다."}
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('주소 검색', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '배달 받을 주소를\n검색해주세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '예) 니즈파인로 123',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
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
            const Divider(height: 32),

            // Search Results
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  if(result.containsKey('subtitle') && result['subtitle']!.isNotEmpty) {
                    return ListTile(
                      title: Text(result['title']!),
                      subtitle: Text(result['subtitle']!),
                      onTap: () {
                        // TODO: Implement address selection and return to previous screen
                      },
                    );
                  } else if (result['title'] == "검색 결과가 없습니다.") {
                    return const ListTile(
                      title: Text("검색 결과가 없습니다."),
                    );
                  } else {
                     return ListTile(
                      title: Text("    ${result['title']!}"), // Indent for items without subtitle
                      onTap: () {
                        // TODO: Implement address selection and return to previous screen
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
