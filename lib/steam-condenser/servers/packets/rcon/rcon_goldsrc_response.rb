# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2008-2012, Sebastian Staudt

require 'steam-condenser/servers/packets/base_packet'

module SteamCondenser::SteamServers::Packets::RCON

  # This packet class represents a RCON response packet sent by a GoldSrc
  # server
  #
  # It is used to transport the output of a command from the server to the
  # client which requested the command execution.
  #
  # @author Sebastian Staudt
  # @see GoldSrcSteamServer#rcon_exec
  class RCONGoldSrcResponse

    include SteamCondenser::SteamServers::Packets::BasePacket

    # Creates a RCON command response for the given command output
    #
    # @param [String] command_response The output of the command executed on
    #        the server
    def initialize(command_response)
      super RCON_GOLDSRC_RESPONSE_HEADER, command_response
    end

    # Returns the output of the command execution
    #
    # @return [String] The output of the command
    def response
      @content_data.string[0..-3]
    end

  end
end
