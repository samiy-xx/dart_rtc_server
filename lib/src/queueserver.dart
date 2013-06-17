part of rtc_server;

class QueueServer extends WebSocketServer implements ContainerContentsEventListener {
  static final _logger = new Logger("dart_rtc_server.QueueServer");
  QueueContainer _queueContainer;

  QueueServer() : super() {

    registerHandler(PACKET_TYPE_PEERCREATED, handlePeerCreated);
    registerHandler(PACKET_TYPE_USERMESSAGE, handleUserMessage);
    registerHandler(PACKET_TYPE_NEXT, handleNextUser);
    registerHandler(PACKET_TYPE_REMOVEUSER, handleRemoveUserCommand);

    _queueContainer = new QueueContainer(this);
    _queueContainer.subscribe(this);
  }


  void onCountChanged(BaseContainer bc) {
    _logger.info("Container count changed ${bc.count}");
    displayStatus();
  }

  String displayStatus() {
    _logger.info("Users: ${_container.userCount} Channels: ${_queueContainer.channelCount}");
  }

  // Override
  void handleIncomingHelo(HeloPacket hp, WebSocket c) {
    super.handleIncomingHelo(hp, c);
    try {
      if (hp.channelId == null || hp.channelId.isEmpty) {
        c.close(1003, "Specify channel id");
        return;
      }

      User u = _container.findUserByConn(c);

      Channel chan = _queueContainer.findChannel(hp.channelId);
      if (chan == null)
        chan = _queueContainer.createChannelWithId(hp.channelId);
      chan.join(u);
    } catch(e, s) {
      _logger.severe(e);
      _logger.info(s);
    }
  }

  void handlePeerCreated(PeerCreatedPacket pcp, WebSocket c) {
    User user = _container.findUserByConn(c);
    User other = _container.findUserById(pcp.id);

    if (user != null && other != null)
      user.talkTo(other);
  }

  void handleRemoveUserCommand(RemoveUserCommand p, WebSocket c) {
    try {
      User user = _container.findUserByConn(c);
      User other = _container.findUserById(p.id);

      if (user == null || other == null) {
        _logger.warning("(channelserver.dart) User was not found");
        return;
      }

      Channel channel = _queueContainer.findChannel(p.channelId);
      if (user == channel.owner)
        channel.leave(other);
    } catch(e) {
      _logger.severe("Error: $e");
    }
  }

  void handleNextUser(NextPacket p, WebSocket c) {
    try {
      User user = _container.findUserByConn(c);
      User other = _container.findUserById(p.id);

      if (user == null || other == null) {
        _logger.warning("(channelserver.dart) User was not found");
        return;
      }

      QueueChannel channel = _queueContainer.findChannel(p.channelId);
      if (user == channel.owner)
        channel.next();
    } catch(e) {
      _logger.severe("Error: $e");
    }
  }

  void handleUserMessage(UserMessage um, WebSocket c) {
    try {
      if (um.id == null || um.id.isEmpty) {
        print ("id was null or empty");
        return;
      }
      User user = _container.findUserByConn(c);
      User other = _container.findUserById(um.id);

      if (user == null || other == null) {
        _logger.warning("(channelserver.dart) User was not found");
        return;
      }

      um.id = user.id;

      sendToClient(other.connection, PacketFactory.get(um));

    } on NoSuchMethodError catch(e) {
      _logger.severe("Error: $e");
    } catch(e) {
      _logger.severe("Error: $e");
    }
  }
}

