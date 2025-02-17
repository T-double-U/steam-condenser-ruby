# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2008-2012, Sebastian Staudt

require 'steam-condenser/error/timeout'
require 'steam-condenser/servers/base_server'
require 'steam-condenser/servers/packets/a2m_get_servers_batch2_packet'
require 'steam-condenser/servers/sockets/master_server_socket'

module SteamCondenser

  module SteamServers

    # This class represents a Steam master server and can be used to get game
    # servers which are publicly available
    #
    # An intance of this class can be used much like Steam's server browser to get
    # a list of available game servers, including filters to narrow down the search
    # results.
    #
    # @author Sebastian Staudt
    class MasterSteamServer

      include BaseSteamServer
      include SteamCondenser::Logging

      # The default number of allowed retries
      @@retries = 3

      # The master server address to query for GoldSrc game servers
      GOLDSRC_MASTER_SERVER = 'hl1master.steampowered.com', 27011

      # The master server address to query for Source game servers
      SOURCE_MASTER_SERVER = 'hl2master.steampowered.com', 27011

      # The region code for the US east coast
      REGION_US_EAST_COAST = 0x00

      # The region code for the US west coast
      REGION_US_WEST_COAST = 0x01

      # The region code for South America
      REGION_SOUTH_AMERICA = 0x02

      # The region code for Europe
      REGION_EUROPE = 0x03

      # The region code for Asia
      REGION_ASIA = 0x04

      # The region code for Australia
      REGION_AUSTRALIA = 0x05

      # The region code for the Middle East
      REGION_MIDDLE_EAST = 0x06

      # The region code for Africa
      REGION_AFRICA = 0x07

      # The region code for the whole world
      REGION_ALL = 0xFF

      # Sets the number of consecutive requests that may fail, before getting
      # the server list is cancelled (default: 3)
      #
      # @param [Fixnum] retries The number of allowed retries
      def self.retries=(retries)
        @@retries = retries
      end

      # Initializes the socket to communicate with the master server
      #
      # @see MasterSteamServerSocket
      def init_socket
        @socket = Sockets::MasterSteamServerSocket.new @ip_address, @port
      end

      # Returns a list of game server matching the given region and filters
      #
      # Filtering:
      # Instead of filtering the results sent by the master server locally, you
      # should at least use the following filters to narrow down the results sent
      # by the master server.
      #
      # Available filters:
      #
      # * `\type\d`: Request only dedicated servers
      # * `\secure\1`: Request only secure servers
      # * `\gamedir\[mod]`: Request only servers of a specific mod
      # * `\map\[mapname]`: Request only servers running a specific map
      # * `\linux\1`: Request only linux servers
      # * `\empty\1`: Request only **non**-empty servers
      # * `\full\1`: Request only servers **not** full
      # * `\proxy\1`: Request only spectator proxy servers
      #
      # @note Receiving all servers from the master server is taking quite some
      #       time.
      # @param [Fixnum] region_code The region code to specify a location of the
      #        game servers
      # @param [String] filters The filters that game servers should match
      # @param [Boolean] force Return a list of servers even if an error occured
      #        while fetching them from the master server
      # @raise [Error::Timeout] if too many timeouts occur while querying the
      #        master server
      # @return [Array<Array<String>>] A list of game servers matching the given
      #         region and filters
      # @see A2M_GET_SERVERS_BATCH2_Packet
      # @see MasterSteamServer.retries=
      def servers(region_code = MasterSteamServer::REGION_ALL, filters = '', force = false)
        finished       = false
        current_server = '0.0.0.0:0'
        server_array   = []

        begin
          failsafe do
            fail_count = 0
            begin
              @socket.send_packet Packets::A2M_GET_SERVERS_BATCH2_Packet.new(region_code, current_server, filters)
              begin
                servers = @socket.reply.servers
                servers.each do |server|
                  if server == '0.0.0.0:0'
                    finished = true
                  else
                    current_server = server
                    server_array << server.split(':')
                  end
                end
                fail_count = 0
              rescue Error::Timeout
                raise $! if (fail_count += 1) == @@retries
                log.info "Request to master server #@ip_address timed out, retrying..."
              end
            end while !finished
          end
        rescue Error::Timeout
          raise $! unless force
        end

        server_array.uniq
      end

    end
  end
end
