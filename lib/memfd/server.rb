require 'socket'

class Memfd
  class Server
    def initialize(path)
      @server = UNIXServer.new(path)
      @memfd = nil
      @sockets = []
    end

    def accept
      @sockets << @server.accept
    end

    def accept_nonblock
      sock = nil
      begin
        sock = @server.accept_nonblock
      rescue IO::WaitReadable, Errno::EINTR
        IO.select([@server])
        retry
      end
      @sockets << sock
    end

    def memfd=(memfd)
      @memfd = memfd
    end

    def write
      @sockets.each do |sock|
        sock.send_io(@memfd.io)
      end
    end

    def close
      @sockets.each(&:close)
    end
  end
end