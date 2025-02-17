# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2008-2012, Sebastian Staudt

require 'steam-condenser/servers/packets/rcon/base_packet'

module SteamCondenser::SteamServers::Packets::RCON

  # This packet class represents a SERVERDATA_AUTH_RESPONSE packet sent by a
  # Source server
  #
  # It is used to indicate the success or failure of an authentication attempt
  # of a client for RCON communication.
  #
  # @author Sebastian Staudt
  # @see SourceSteamServer#rcon_auth
  class RCONAuthResponse

    include BasePacket

    # Creates a RCON authentication response for the given request ID
    #
    # The request ID of the packet will match the client's request if
    # authentication was successful
    #
    # @param [Fixnum] request_id The request ID of the RCON connection
    def initialize(request_id)
      super request_id, SERVERDATA_AUTH_RESPONSE, ''
    end

  end
end
