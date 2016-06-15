require 'memfd/version' unless defined? MemFD::VERSION
require 'memfd/memfd_ext'
require 'fcntl'

class Memfd
  def self.map(name, size = MFD_DEF_SIZE, offset = 0)
    new(name, MFD_CLOEXEC | MFD_ALLOW_SEALING).map(size, offset)
  end

  def seals
    io.fcntl(F_GET_SEALS)
  end

  def seal(flags)
    if flags & F_SEAL_WRITE == F_SEAL_WRITE
      unmap(false)
    end
    io.fcntl(F_ADD_SEALS, flags)
  end

  def seal!
    seal F_SEAL_SHRINK | F_SEAL_GROW | F_SEAL_WRITE | F_SEAL_SEAL
  end
end