part of rtc_server;

class WheelUser extends User {
  WheelUser.With(UserContainer uc, String id, WebSocket conn) : super.With(uc, id, conn);
}
