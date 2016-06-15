require 'mkmf'

dir_config('memfd')

if RUBY_PLATFORM !~ /linux/
  abort "-----\n memfd only runs on Linux\n-----"
end

def require_header(header)
  abort "-----\nCannot find #{header}\n----" unless have_header(header)
end

require_header "sys/syscall.h"
require_header "linux/fcntl.h"
require_header "sys/mman.h"

$CFLAGS << " -std=c99 -pedantic -Wall -fno-strict-aliasing"

create_makefile('memfd/memfd_ext')