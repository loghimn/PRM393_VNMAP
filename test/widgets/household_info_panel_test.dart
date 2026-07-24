import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/household_model.dart';
import 'package:vietnam_geo_dashboard/models/province_model.dart';
import 'package:vietnam_geo_dashboard/widgets/map/household_info_panel.dart';
import '../screens/test_helpers/mock_providers.dart';
import '../screens/test_helpers/widget_test_utils.dart';

/// Tạo sample commune
final ProvinceModel testCommune = ProvinceModel(
  name: 'Phường Bến Thành',
  density: 10000,
  population: 15000,
  areaKm2: 1.5,
  geometry: {'type': 'Polygon', 'coordinates': []},
  properties: {},
);

/// Tạo sample households
final List<Household> sampleHouseholds = [
  Household(
    id: 1,
    householdCode: 'HH001',
    headOfHousehold: 'Nguyễn Văn A',
    houseNumber: '123',
    street: 'Đường Lê Lợi',
    neighborhood: 'P.Bến Thành',
    ward: 'Q.1',
    city: 'TP.HCM',
    phone: '0909123456',
    email: 'a@example.com',
    population: 4,
    longitude: 106.6297,
    latitude: 10.8231,
    createdBy: 1,
  ),
  Household(
    id: 2,
    householdCode: 'HH002',
    headOfHousehold: 'Trần Thị B',
    houseNumber: '456',
    street: 'Đường Nguyễn Huệ',
    neighborhood: 'P.Bến Thành',
    ward: 'Q.1',
    city: 'TP.HCM',
    population: 3,
    longitude: 106.7042,
    latitude: 10.7756,
    createdBy: 1,
  ),
  Household(
    id: 3,
    householdCode: 'HH003',
    headOfHousehold: 'Lê Văn C',
    phone: '0912345678',
    neighborhood: 'P.Bến Thành',
    ward: 'Q.1',
    city: 'TP.HCM',
    population: 2,
    createdBy: 1,
  ),
];

/// Factory helper: tạo FakeProvinceProvider với state mong muốn
FakeProvinceProvider createProvinceProvider({
  ProvinceModel? commune,
  List<Household>? households,
  bool isLoadingHouseholds = false,
}) {
  final provider = FakeProvinceProvider();
  provider.selectedCommune = commune ?? testCommune;
  provider.selectedCommuneHouseholds = households ?? sampleHouseholds;
  provider.isLoadingHouseholds = isLoadingHouseholds;
  return provider;
}

/// Helper: pump HouseholdInfoPanel trong Stack (vì widget dùng Positioned)
/// Mặc định commune = testCommune, pass null để test empty state
Future<void> pumpPanel(
  WidgetTester tester, {
  ProvinceModel? commune,
  List<Household>? households,
  bool isLoadingHouseholds = false,
}) async {
  final provider = FakeProvinceProvider();
  // Mặc định commune = testCommune, chỉ null khi được truyền explicit null
  provider.selectedCommune = commune ?? testCommune;
  provider.selectedCommuneHouseholds = households ?? sampleHouseholds;
  provider.isLoadingHouseholds = isLoadingHouseholds;
  await tester.pumpScreen(
    Stack(children: const [HouseholdInfoPanel()]),
    overrides: ProviderOverrides(province: provider),
  );
}

void main() {
  group('HouseholdInfoPanel', () {
    testWidgets(
      'trả về SizedBox (không render nội dung) khi selectedCommune == null',
      (tester) async {
        // Dùng FakeProvinceProvider với selectedCommune = null
        final provider = FakeProvinceProvider();
        await tester.pumpScreen(
          Stack(children: const [HouseholdInfoPanel()]),
          overrides: ProviderOverrides(province: provider),
        );

        // Không render text header hay nội dung nào
        expect(find.textContaining('Hộ gia đình'), findsNothing);
        expect(find.textContaining('hộ'), findsNothing);
      },
    );

    testWidgets('hiển thị header với tên commune và số hộ', (tester) async {
      await pumpPanel(tester);

      // Tiêu đề "Hộ gia đình - Phường Bến Thành"
      expect(find.text('Hộ gia đình - Phường Bến Thành'), findsOneWidget);
      // Số hộ: "3 hộ"
      expect(find.text('3 hộ'), findsOneWidget);
    });

    testWidgets('hiển thị CircularProgressIndicator khi isLoadingHouseholds', (
      tester,
    ) async {
      await pumpPanel(tester, isLoadingHouseholds: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hiển thị "Không có hộ gia đình nào" khi danh sách rỗng', (
      tester,
    ) async {
      await pumpPanel(tester, households: []);

      expect(find.text('Không có hộ gia đình nào'), findsOneWidget);
    });

    testWidgets('hiển thị danh sách hộ gia đình', (tester) async {
      await pumpPanel(tester);

      // Tên chủ hộ
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('Trần Thị B'), findsOneWidget);
      expect(find.text('Lê Văn C'), findsOneWidget);

      // Địa chỉ
      // Hộ A: "123 Đường Lê Lợi" (có houseNumber và street)
      expect(find.text('123 Đường Lê Lợi'), findsOneWidget);
      // Hộ B: "456 Đường Nguyễn Huệ"
      expect(find.text('456 Đường Nguyễn Huệ'), findsOneWidget);
    });

    testWidgets('hiển thị icon phone cho hộ có số điện thoại', (tester) async {
      await pumpPanel(tester);

      final phoneIcons = find.byIcon(Icons.phone);
      // Hộ A có phone "0909123456", Hộ C có phone "0912345678"
      // Hộ B không có phone → chỉ 2 icons
      expect(phoneIcons, findsNWidgets(2));
    });

    testWidgets('tap vào một hộ thì KHÔNG gọi select (chỉ display)', (
      tester,
    ) async {
      final provider = createProvinceProvider();
      await tester.pumpScreen(
        Stack(children: const [HouseholdInfoPanel()]),
        overrides: ProviderOverrides(province: provider),
      );

      // Tap vào tên chủ hộ
      await tester.tap(find.text('Nguyễn Văn A'));
      await tester.pumpAndSettle();

      // Xác nhận không crash — widget chỉ display
      expect(provider.selectedProvince, isNull);
    });

    testWidgets('cập nhật khi selectedCommune thay đổi', (tester) async {
      final provider = createProvinceProvider();
      await tester.pumpScreen(
        Stack(children: const [HouseholdInfoPanel()]),
        overrides: ProviderOverrides(province: provider),
      );

      // Ban đầu: "Phường Bến Thành"
      expect(find.text('Hộ gia đình - Phường Bến Thành'), findsOneWidget);
      expect(find.text('3 hộ'), findsOneWidget);

      // Đổi commune
      final newCommune = ProvinceModel(
        name: 'Phường Bến Nghé',
        density: 12000,
        population: 18000,
        areaKm2: 1.2,
        geometry: {'type': 'Polygon', 'coordinates': []},
        properties: {},
      );
      provider.selectedCommune = newCommune;
      provider.selectedCommuneHouseholds = sampleHouseholds.take(1).toList();
      provider.notifyListeners();
      await tester.pumpAndSettle();

      // Cập nhật
      expect(find.text('Hộ gia đình - Phường Bến Nghé'), findsOneWidget);
      expect(find.text('1 hộ'), findsOneWidget);
    });

    testWidgets('không hiển thị icon phone nếu phone == null', (tester) async {
      // Tạo households với phone == null cho tất cả
      final householdsNoPhone = sampleHouseholds
          .map(
            (h) => Household(
              id: h.id,
              householdCode: h.householdCode,
              headOfHousehold: h.headOfHousehold,
              houseNumber: h.houseNumber,
              street: h.street,
              neighborhood: h.neighborhood,
              ward: h.ward,
              city: h.city,
              population: h.population,
              createdBy: h.createdBy,
            ),
          )
          .toList();

      await pumpPanel(tester, households: householdsNoPhone);

      // Không có icon phone nào
      expect(find.byIcon(Icons.phone), findsNothing);
    });
  });
}
