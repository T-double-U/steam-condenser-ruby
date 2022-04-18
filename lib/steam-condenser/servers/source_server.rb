# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2008-2013, Sebastian Staudt

require 'steam-condenser/error/rcon_ban'
require 'steam-condenser/error/rcon_no_auth'
require 'steam-condenser/servers/game_server'
require 'steam-condenser/servers/master_server'
require 'steam-condenser/servers/packets/rcon/rcon_auth_request'
require 'steam-condenser/servers/packets/rcon/rcon_auth_response'
require 'steam-condenser/servers/packets/rcon/rcon_exec_request'
require 'steam-condenser/servers/packets/rcon/rcon_terminator'
require 'steam-condenser/servers/sockets/rcon_socket'
require 'steam-condenser/servers/sockets/source_socket'

module SteamCondenser

  module SteamServers

    # This class represents a Source game server and can be used to query
    # information about and remotely execute commands via RCON on the server
    #
    # A Source game server is an instance of the Source Dedicated SteamServer (SrcDS)
    # running games using Valve's Source engine, like Counter-Strike: Source,
    # Team Fortress 2 or Left4Dead.
    #
    # @author Sebastian Staudt
    # @see GoldSrcSteamServer
    class SourceSteamServer

      include GameSteamServer
      include SteamCondenser::Logging

      # Returns a master server instance for the default master server for Source
      # games
      #
      # @return [MasterSteamServer] The Source master server
      def self.master
        MasterSteamServer.new *MasterSteamServer::SOURCE_MASTER_SERVER
      end

      # Creates a new instance of a server object representing a Source server,
      # i.e. SrcDS instance
      #
      # @param [String] address Either an IP address, a DNS name or one of them
      #        combined with the port number. If a port number is given, e.g.
      #        'server.example.com:27016' it will override the second argument.
      # @param [Fixnum] port The port the server is listening on
      # @raise [Error] if an host name cannot be resolved
      def initialize(address, port = 27015)
        super
      end

      # Disconnects the TCP-based channel used for RCON commands
      #
      # @see RCONSocket#close
      def disconnect
        @rcon_socket.close
      end

      # Initializes the sockets to communicate with the Source server
      #
      # @see RCONSocket
      # @see SourceSocket
      def init_socket
        @rcon_socket = Sockets::RCONSocket.new @ip_address, @port
        @socket      = Sockets::SourceSocket.new @ip_address, @port
      end

      # Authenticates the connection for RCON communication with the server
      #
      # @param [String] password The RCON password of the server
      # @return [Boolean] whether authentication was successful
      # @see #rcon_authenticated?
      # @see #rcon_exec
      def rcon_auth(password)
        @rcon_request_id = rand 2**16

        @rcon_socket.send_packet Packets::RCON::RCONAuthRequest.new @rcon_request_id, password

        reply = @rcon_socket.reply
        raise Error::RCONBan if reply.nil?
        reply = @rcon_socket.reply
        @rcon_authenticated = reply.request_id == @rcon_request_id
      end

      # Remotely executes a command on the server via RCON
      #
      # @param [String] command The command to execute on the server via RCON
      # @return [String] The output of the executed command
      # @raise [RCONBanException] if the IP of the local machine has been banned on
      #        the game server
      # @raise [RCONNoAuthException] if not authenticated with the server
      # @see #rcon_auth
      def rcon_exec(command)
        raise Error::RCONNoAuth unless @rcon_authenticated

        @rcon_socket.send_packet Packets::RCON::RCONExecRequest.new(@rcon_request_id, command)

        is_multi = false
        response = []
        begin
          response_packet = @rcon_socket.reply

          if response_packet.nil? || response_packet.is_a?(Packets::RCON::RCONAuthResponse)
            @rcon_authenticated = false
            raise Error::RCONNoAuth
          end

          if !is_multi && response_packet.response.size > 0
            is_multi = true
            @rcon_socket.send_packet Packets::RCON::RCONTerminator.new(@rcon_request_id)
          end

          response << response_packet.response
        end while is_multi && !(response[-2] == '' && response[-1] == '')

        response.join('').strip
      end

    end
  end
end
