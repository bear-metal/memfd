#ifndef MEMFD_EXT_H
#define MEMFD_EXT_H

#include "ruby/ruby.h"

#include <unistd.h>
#include <sys/syscall.h>
#include <sys/mman.h>
#include <linux/fcntl.h>
#include <errno.h>

#define MFD_DEF_SIZE 8192

// No libc helper for this syscall
#ifndef SYS_memfd_create
#ifdef __x86_64__
#define SYS_memfd_create 319
#endif
#ifdef __i386__
#define SYS_memfd_create 356
#endif
#ifdef __sparc__
#define SYS_memfd_create 348
#endif
#ifdef __ia64__
#define SYS_memfd_create 1340
#endif
#endif

#ifndef MFD_CLOEXEC
#define MFD_CLOEXEC       0x0001U
#endif

#ifndef MFD_ALLOW_SEALING
#define MFD_ALLOW_SEALING 0x0002U
#endif

#ifndef F_LINUX_SPECIFIC_BASE
#define F_LINUX_SPECIFIC_BASE 1024
#endif

#ifndef F_ADD_SEALS

#define F_ADD_SEALS     (F_LINUX_SPECIFIC_BASE + 9)
#define F_GET_SEALS     (F_LINUX_SPECIFIC_BASE + 10)

#define F_SEAL_SEAL     0x0001  /* prevent further seals from being set */
#define F_SEAL_SHRINK   0x0002  /* prevent file from shrinking */
#define F_SEAL_GROW     0x0004  /* prevent file from growing */
#define F_SEAL_WRITE    0x0008  /* prevent writes */

#endif

extern VALUE rb_cMemfd;
extern VALUE rb_eMemfd;

const rb_data_type_t memfd_type;

typedef struct {
    VALUE name;
    VALUE flags;
    VALUE io;
      int fd;
   size_t size;
     void *region;
} memfd_wrapper;

#define GetMemfd(obj) \
    memfd_wrapper *memfd = NULL; \
    TypedData_Get_Struct(obj, memfd_wrapper, &memfd_type, memfd); \

#define MemfdError(error, message) \
    if (memfd->fd != -1) { \
     if (memfd->io != Qnil) rb_io_close(memfd->io); \
        close(memfd->fd); \
        memfd->fd = -1; \
    } \
    rb_raise(error, message); \

#define MemfdIOError(message) MemfdError(rb_eIOError, message)
#define MemfdAllocError(message) MemfdError(rb_eMemfd, message)

#endif