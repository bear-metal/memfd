$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'memfd'
require 'benchmark'
require 'securerandom'

payload = SecureRandom.hex * 50000
payload_size = payload.size

memfd = Memfd.map('zero copy')
memfd.io.write(payload)
memfd.io.rewind
memfd.seal!
memfd_payload = "#{memfd.fd}|#{memfd.size}"

iterations = 10000

Benchmark.bmbm do |results|
  results.report("Standard UNIX sockets") do
    path = "/tmp/memfd-#{SecureRandom.hex}"
    server = UNIXServer.new(path)
    pid = fork do
      client = UNIXSocket.new(path)
      while true do
        res = client.read(payload_size)
        break if res == "STOP"
      end
      client.close
    end
    server_socket = server.accept
     
    iterations.times do
      server_socket.write(payload)
    end
    server_socket.write("STOP")
    server_socket.close
  end

  results.report("Zero-copy transfer") do
    path = "/tmp/memfd-#{SecureRandom.hex}"
    server = UNIXServer.new(path)
    pid = fork do
      client = UNIXSocket.new(path)
      while true do
        res = client.read(memfd_payload.size)
        break if res == "STOP"
        fd, size = res.split("|")
        Memfd.read(fd.to_i, size.to_i)
      end
      client.close
    end
    server_socket = server.accept
     
    iterations.times do
      server_socket.write memfd_payload
    end
    server_socket.write("STOP")
    server_socket.close
  end
end