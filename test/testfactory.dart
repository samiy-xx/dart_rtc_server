part of rtc_server_tests;

class TestFactory {
  static User getTestUser(String id, WebSocket ws) {
    return new User(id, ws);
  }

  static String getRandomId() {
    return Util.generateId(4);
  }
}

