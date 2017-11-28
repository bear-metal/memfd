require 'memfd'
require 'minitest/autorun'
require 'socket'

class TestMemfd < Minitest::Test
  def test_seals
    mfd = Memfd.new
    assert_equal 0, mfd.seals
    mfd = Memfd.map("test_seals")
    assert_equal 0, mfd.seals
    mfd.seal(Memfd::F_SEAL_WRITE)
    assert_equal Memfd::F_SEAL_WRITE, mfd.seals
  ensure
    mfd.unmap
  end

  def test_fd
    mfd = Memfd.new
    assert_equal mfd.fd, mfd.io.fileno
    mfd.unmap
    assert_equal(-1, mfd.fd)
  end

  def test_name
    mfd = Memfd.new("test_name", Memfd::MFD_CLOEXEC | Memfd::MFD_ALLOW_SEALING)
    assert_equal "test_name", mfd.name
    mfd = Memfd.new
    assert_equal 8, mfd.name.size
  end

  def test_flags
    flags = Memfd::MFD_CLOEXEC | Memfd::MFD_ALLOW_SEALING
    mfd = Memfd.new
    assert_equal flags, mfd.flags
    mfd = Memfd.new("test_flags", flags)
    assert_equal flags, mfd.flags
    mfd = Memfd.new("test_flags", Memfd::MFD_CLOEXEC)
    assert_equal Memfd::MFD_CLOEXEC, mfd.flags
  end

  def test_map
    mfd = Memfd.map('test_alloc', 2048)
    mfd.unmap
    assert_equal(-1, mfd.fd)
  ensure
    mfd.unmap
  end

  def test_size
    mfd = Memfd.map('test_alloc', 2048)
    assert_equal 2048, mfd.size
  ensure
    mfd.unmap
  end

  def test_read_write
    mfd = Memfd.map('test_read_write', 2048)
    assert_equal 4, mfd.io.write('test')
    mfd.io.rewind
    assert_equal 'test', mfd.io.read(4)
    assert_equal 1, mfd.io.write('X')
    mfd.io.rewind
    assert_equal 'testX', mfd.io.read(5)
  ensure
    mfd.unmap
  end

  def test_sealing_writes
    mfd = Memfd.map('test_sealing')
    assert_equal 4, mfd.io.write('test')
    mfd.seal(Memfd::F_SEAL_WRITE)
    assert (mfd.seals & Memfd::F_SEAL_WRITE == Memfd::F_SEAL_WRITE)
    assert_raises Errno::EPERM do
      mfd.io.rewind
    end
  end

  def test_sealing_seals
    mfd = Memfd.map('test_sealing')
    assert_equal 4, mfd.io.write('test')
    mfd.seal(Memfd::F_SEAL_SEAL)
    assert (mfd.seals & Memfd::F_SEAL_SEAL == Memfd::F_SEAL_SEAL)
    assert_raises Errno::EPERM do
      mfd.seal(Memfd::F_SEAL_WRITE)
    end
  end

  def test_sealing_growth
    mfd = Memfd.map('test_sealing', 4)
    assert_equal 4, mfd.io.write('test')
    mfd.seal(Memfd::F_SEAL_GROW)
    assert (mfd.seals & Memfd::F_SEAL_GROW == Memfd::F_SEAL_GROW)
    mfd.io.rewind
    assert_equal 1, mfd.io.write("X")
    assert_equal "est", mfd.io.read
  end

  def test_fork
    mfd = Memfd.map('test_fork')
    msg = "message from parent #{Process.pid}"
    mfd.io.write(msg)
    10.times do
      fork do
        mfd.io.rewind
        p "Child #{Process.pid}: #{mfd.io.read(msg.size)}"
      end
    end
    Process.wait
  end

  def test_seal_all
    mfd = Memfd.map('test_sealing')
    assert_equal 4, mfd.io.write('test')
    mfd.seal!
    assert_raises Errno::EPERM do
      mfd.seal(Memfd::F_SEAL_WRITE)
    end
    assert_raises Errno::EPERM do
      mfd.io.rewind
    end
  end

  def test_zero_copy_xfer
    payload = 'test_zero_copy_xfer'
    mfd = Memfd.map('zero copy')
    size = mfd.io.write(payload)
    mfd.io.rewind
    mfd.seal!
    server, client = UNIXSocket.pair
    server.send "#{mfd.fd}|#{mfd.size}", 0
    fd, size = client.recv(1024).split("|")
    assert_equal payload.dup, Memfd.read(fd.to_i, size.to_i)
  end
end