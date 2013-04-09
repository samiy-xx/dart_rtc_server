part of rtc_server_tests;

class ChannelTests {
  run() {
    group('ChannelTests', () {
      //TestableWebSocketConnection ws;
      TestableServer server;
      ChannelContainer container;
      Channel c;

      String channelId;
      String userId;
      int channelLimit;

      setUp(() {
        userId = Util.generateId(4);
        channelId = Util.generateId(4);
        channelLimit = 5;
        server = new TestableServer();
        container = new ChannelContainer(server);

        //ws  = new TestableWebSocketConnection();
        c = new Channel.With(container, channelId, channelLimit);
      });

      tearDown(() {
        c = null;
        //ws = null;
        container = null;
        server = null;
      });

      test("Channel, When created, is not null", () {
        expect(c, isNotNull);
      });

      test("Channel, When created, has properties", () {
        expect(c.id, equals(channelId));
        expect(c.channelLimit, equals(channelLimit));
        expect(c.userCount, equals(0));
      });

      test("Channel, user limit, can be changed", () {
        expect(c.channelLimit, equals(channelLimit));
        c.channelLimit = 10;
        expect(c.channelLimit, equals(10));
      });

      test("Channel, User List, Can add users", () {
        User u = TestFactory.getTestUser(userId, null);
        c.join(u);
        expect(c.userCount, equals(1));
        expect(c.users[0], equals(u));
      });

      test("Channel, User List, Can remove users", () {
        User u = TestFactory.getTestUser(userId, null);
        c.join(u);
        expect(c.userCount, equals(1));
        expect(c.users[0], equals(u));
        c.leave(u);
        expect(c.userCount, equals(0));
      });

      test("Channel, userlimit exceeded, canJoin returns false", () {
        expect(c.canJoin, equals(true));
        for (int i = 0; i < channelLimit; i++) {
          c.join(TestFactory.getTestUser(TestFactory.getRandomId(), null));
        }
        expect(c.canJoin, equals(false));
      });

      test("Channel, join user with userlimit exceeded, returns false and user not joined", () {
        for (int i = 0; i < channelLimit; i++) {
          expect(c.join(TestFactory.getTestUser(TestFactory.getRandomId(), null)), equals(true));
          expect(c.userCount, equals(i + 1));
        }
        expect(c.join(TestFactory.getTestUser(TestFactory.getRandomId(), null)), equals(false));
        expect(c.userCount, equals(5));
      });

      test("Channel, joining/leaving, fires event", () {
        User u = TestFactory.getTestUser(userId, null);
        MockChannelEventListener l = new MockChannelEventListener();
        c.subscribe(l);
        bool wasJoined = false;
        bool wasLeft = false;

        l.joinCallback = (Channel chan, User user) {
          expect(chan, equals(c));
          expect(user, equals(u));
          wasJoined = true;
        };

        l.leaveCallback = (Channel chan, User user) {
          expect(chan, equals(c));
          expect(user, equals(u));
          wasLeft = true;
        };

        c.join(u);
        c.leave(u);

        expect(wasJoined, equals(true));
        expect(wasLeft, equals(true));
        //Timer t = new Timer(100, (_) {
        //  expect(wasJoined, equals(true));
        //  expect(wasLeft, equals(true));
        //});

      });

      test("Channel, Joining channel, Packet gets sent", () {
        User first = TestFactory.getTestUser(TestFactory.getRandomId(), null);
        User second = TestFactory.getTestUser(TestFactory.getRandomId(), null);
        User third = TestFactory.getTestUser(TestFactory.getRandomId(), null);

        c.join(first);
        expect(server.packetsSent.length, equals(1));

        c.join(second);
        expect(server.packetsSent.length, equals(4));
        expect(server.packetsSent[0].packetType, equals(PACKET_TYPE_CHANNEL));
        expect(server.packetsSent[1].packetType, equals(PACKET_TYPE_JOIN));
        expect(server.packetsSent[1].id, equals(second.id));
        expect(server.packetsSent[2].packetType, equals(PACKET_TYPE_ID));
        expect(server.packetsSent[2].id, equals(first.id));

        c.join(third);
        expect(server.packetsSent.length, equals(9));
        expect(server.packetsSent[2].packetType, equals(PACKET_TYPE_ID));
        expect(server.packetsSent[3].packetType, equals(PACKET_TYPE_CHANNEL));
        expect(server.packetsSent[4].packetType, equals(PACKET_TYPE_JOIN));
        expect(server.packetsSent[5].packetType, equals(PACKET_TYPE_ID));
      });

      test("Channel, Leaving channel, Packet gets sent", () {
        User first = TestFactory.getTestUser(TestFactory.getRandomId(), null);
        User second = TestFactory.getTestUser(TestFactory.getRandomId(), null);
        User third = TestFactory.getTestUser(TestFactory.getRandomId(), null);

        c.join(first);
        c.join(second);
        c.join(third);

        server.packetsSent.clear();

        c.leave(first);
        expect(server.packetsSent.length, equals(2));
        expect(server.packetsSent[0].packetType, equals(PACKET_TYPE_BYE));
        expect(server.packetsSent[1].packetType, equals(PACKET_TYPE_BYE));
      });
    });

  }
}


