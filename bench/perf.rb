$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'memfd'
require 'benchmark'
require 'securerandom'
require 'socket'

payload = SecureRandom.hex * 50000
payload_size = payload.size

memfd = Memfd.map('zero copy')
memfd.write(payload)
memfd.seal!

iterations = 10000

Benchmark.bmbm do |results|
  results.report("Standard UNIX sockets") do
    path = "/tmp/memfd-#{SecureRandom.hex}"
    server = UNIXServer.new(path)
    pid = fork do
      client = UNIXSocket.new(path)
      while true do
        client.read(payload_size)
      end
      client.close
    end
    server_socket = server.accept
     
    iterations.times do
      server_socket.write(payload)
    end
    server_socket.close
  end

  results.report("Zero-copy transfer") do
    path = "/tmp/memfd-#{SecureRandom.hex}"
    server = Memfd::Server.new(path)
    server.memfd = memfd

    pid = fork do
      client = Memfd::Client.new(path)
      while true do
        begin
          client.read
        rescue SocketError
          break
        end
      end
      client.close
    end

    server.accept
     
    iterations.times do
      server.write
    end
    server.close
  end
end