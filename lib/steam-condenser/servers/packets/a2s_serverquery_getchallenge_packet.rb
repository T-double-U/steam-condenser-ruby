# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2008-2012, Sebastian Staudt

require 'steam-condenser/servers/packets/base_packet'

module SteamCondenser::SteamServers::Packets

  # This packet class represents a A2S_SERVERQUERY_GETCHALLENGE request send to
  # a game server
  #
  # It is used to retrieve a challenge number from the game server, which helps
  # to identify the requesting client.
  #
  # @author Sebastian Staudt
  # @see GameSteamServer#update_challenge_number
  class A2S_SERVERQUERY_GETCHALLENGE_Packet

    include BasePacket

    # Creates a new A2S_SERVERQUERY_GETCHALLENGE request object
    def initialize
      super A2S_SERVERQUERY_GETCHALLENGE_HEADER
    end

  end
end
