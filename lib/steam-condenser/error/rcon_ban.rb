# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2012, Sebastian Staudt

require 'steam-condenser/error'

module SteamCondenser

  # This error class indicates that the IP address your accessing the game
  # server from has been banned by the server
  #
  # You or the server operator will have to unban your IP address on the
  # server.
  #
  # @author Sebastian Staudt
  # @see GameSteamServer#rcon_auth
  class Error::RCONBan < Error

    # Creates a new `Error::RCONBan` instance
    def initialize
      super 'You have been banned from this server.'
    end

  end
end
