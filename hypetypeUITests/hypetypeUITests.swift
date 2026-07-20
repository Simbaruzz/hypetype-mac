import XCTest

// UI-тесты отключены намеренно: hypetype — меню-бар-приложение (accessory) без обычного
// окна, поэтому шаблонные UI-тесты с app.launch() для него неприменимы и просто висли.
// Логика покрыта юнит-тестами в таргете hypetypeTests.
final class hypetypeUITests: XCTestCase {}
