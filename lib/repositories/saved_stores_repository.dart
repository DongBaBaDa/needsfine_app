import 'package:needsfine_app/models/my_list_models.dart';

abstract class SavedStoresRepository {
  Future<List<SavedStore>> fetchSavedStores();
}

/// ✅ 지금은 “저장한 매장 테이블이 없다”고 했으니 더미로.
/// 나중에 Supabase 테이블 생기면 여기만 교체하면 됨.
class DemoSavedStoresRepository implements SavedStoresRepository {
  @override
  Future<List<SavedStore>> fetchSavedStores() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return const [
      SavedStore(id: 's1', name: '을지로 ○○식당', address: '서울 중구 …'),
      SavedStore(id: 's2', name: '성수 △△카페', address: '서울 성동구 …'),
      SavedStore(id: 's3', name: '연남 □□이자카야', address: '서울 마포구 …'),
      SavedStore(id: 's4', name: '광화문 ◇◇국밥', address: '서울 종로구 …'),
      SavedStore(id: 's5', name: '압구정 ☆☆디저트', address: '서울 강남구 …'),
    ];
  }
}
