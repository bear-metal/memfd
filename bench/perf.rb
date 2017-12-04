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

path = "/tmp/memfd-#{SecureRandom.hex}"
server = UNIXServer.new(path)
5.times do
  fork do
    p "-> client #{Process.pid}"
    client = UNIXSocket.new(path)
    while true do
      client.read(payload_size)
    end
    client.close
    p "<- client #{Process.pid}"
  end
end

sockets = []
5.times { sockets << server.accept }

path = "/tmp/memfd-#{SecureRandom.hex}"
memfd_server = Memfd::Server.new(path)
memfd_server.memfd = memfd

5.times do
  fork do
    memfd_client = Memfd::Client.new(path)
    p "-> memfd client #{Process.pid}"
    while true do
      begin
        memfd_client.read
      rescue SocketError
        break
      end
    end
    memfd_client.close
    p "<- memfd client #{Process.pid}"
  end
end

5.times { memfd_server.accept }

sleep 2

Benchmark.bmbm do |results|
  results.report("Standard UNIX sockets") do
    iterations.times do
      sockets.each do |sock|
        sock.write(payload)
      end
    end
  end

  results.report("memfd zero-copy transfer") do
    iterations.times do
      memfd_server.write
    end
  end
end

sockets.each(&:close)
server.close

sleep 1