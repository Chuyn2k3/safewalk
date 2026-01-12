class FakeAPIService {
  Future<bool> checkCompanySubscription(String companyId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return companyId == "renault"; // chỉ Renault là hợp lệ
  }
}
