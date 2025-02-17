# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011-2012, Sebastian Staudt

require 'helper'

class TestSourceSteamServer < Test::Unit::TestCase

  context 'The user' do

    should 'be able to get a master server for Source servers' do
      master = mock
      SteamServers::MasterSteamServer.expects(:new).
        with(*SteamServers::MasterSteamServer::SOURCE_MASTER_SERVER).
        returns master

      assert_equal master, SteamServers::SourceSteamServer.master
    end

  end

  context 'A Source server' do

    setup do
      Socket.stubs(:getaddrinfo).
        with('source', 27015, Socket::AF_INET, Socket::SOCK_DGRAM).
        returns [[nil, nil, 'source', '127.0.0.1']]

      @server = SteamServers::SourceSteamServer.new 'source', 27015
    end

    should 'create client sockets upon initialization' do
      socket = mock
      SteamServers::Sockets::SourceSocket.expects(:new).with('127.0.0.1', 27015).returns socket
      rcon_socket = mock
      SteamServers::Sockets::RCONSocket.expects(:new).with('127.0.0.1', 27015).returns rcon_socket

      @server.init_socket

      assert_same socket, @server.instance_variable_get(:@socket)
      assert_same rcon_socket, @server.instance_variable_get(:@rcon_socket)
    end

    should 'be able to authenticate successfully' do
      reply = mock

      rcon_socket = mock
      rcon_socket.expects(:send_packet).with do |packet|
        reply.expects(:request_id).returns packet.request_id

        packet.is_a? SteamServers::Packets::RCON::RCONAuthRequest
      end
      rcon_socket.expects(:reply).twice.returns(mock).returns(reply)
      @server.instance_variable_set :@rcon_socket, rcon_socket

      assert @server.rcon_auth 'password'
      assert @server.instance_variable_get(:@rcon_authenticated)
    end

    should 'fail to authenticate if the wrong request ID is returned' do
      reply = mock
      reply.expects(:request_id).returns -1

      rcon_socket = mock
      rcon_socket.expects(:send_packet).with { |packet| packet.is_a? SteamServers::Packets::RCON::RCONAuthRequest }
      rcon_socket.expects(:reply).twice.returns(mock).returns(reply)
      @server.instance_variable_set :@rcon_socket, rcon_socket

      assert_not @server.rcon_auth 'password'
      assert_not @server.instance_variable_get(:@rcon_authenticated)
    end

    should 'raise an error if the RCON connection is not authenticated' do
      assert_raises Error::RCONNoAuth do
        @server.rcon_exec 'command'
      end
    end

    should 'close the RCON socket on disconnect' do
      rcon_socket = mock
      rcon_socket.expects(:close)
      @server.instance_variable_set :@rcon_socket, rcon_socket

      @server.disconnect
    end

    context 'with an authenticated RCON connection' do

      setup do
        @rcon_socket = mock
        @rcon_socket.expects(:send_packet).with do |packet|
          packet.is_a?(SteamServers::Packets::RCON::RCONExecRequest) &&
          packet.instance_variable_get(:@content_data).string == "command\0\0" &&
          packet.instance_variable_get(:@request_id) == 1234
        end

        @server.instance_variable_set :@rcon_authenticated, true
        @server.instance_variable_set :@rcon_request_id, 1234
        @server.instance_variable_set :@rcon_socket, @rcon_socket
      end

      should 'reset the connection if the server indicates so' do
        reply = mock
        reply.expects(:is_a?).with(SteamServers::Packets::RCON::RCONAuthResponse).returns true
        @rcon_socket.expects(:reply).returns(reply)

        assert_raises Error::RCONNoAuth do
          @server.rcon_exec 'command'
        end
        assert_not @server.instance_variable_get(:@rcon_authenticated)
      end

      should 'receive the empty response of a command' do
        reply = mock
        reply.expects(:response).twice.returns ''

        @rcon_socket.expects(:reply).returns reply

        assert_equal '', @server.rcon_exec('command')
      end

      should 'receive the response of a command' do
        @rcon_socket.expects(:send_packet).with do |packet|
          packet.is_a?(SteamServers::Packets::RCON::RCONTerminator) &&
          packet.instance_variable_get(:@request_id) == 1234
        end

        reply1 = mock
        reply1.expects(:response).twice.returns 'test'
        reply2 = mock response: 'test'
        reply3 = mock
        reply3.expects(:response).twice.returns ''

        @rcon_socket.expects(:reply).times(4).returns(reply1).returns(reply2).
          returns(reply3).returns(reply3)

        assert_equal 'testtest', @server.rcon_exec('command')
      end

    end

  end

end
