require 'socket'

class Memfd
  class Client
    def initialize(path)
      @client = UNIXSocket.new(path)
    end

    def read(size = MFD_DEF_SIZE)
      io = @client.recv_io
      Memfd.read(io.fileno)
    end

    def close
      @client.close
    end
  end
end