#include "memfd_ext.h"

VALUE rb_cMemfd;
VALUE rb_eMemfd;

static int rb_memfd_syscall_memfd_create(const char *name, unsigned int flags)
{
    int fd;
    fd = syscall(SYS_memfd_create, name, flags);
    if (fd == -1) {
        if(errno == ENOSYS) rb_raise(rb_eNotImpError, "SYS_memfd_create not supported on this kernel");
        rb_sys_fail("memfd_create");
    }
    return fd;
}

static inline void rb_memfd_gc_free(void *ptr)
{
    memfd_wrapper *memfd = (memfd_wrapper *)ptr;
    if (memfd) {
        if (memfd->fd != -1) close(memfd->fd);
        xfree(memfd);
    }
}

static inline void rb_memfd_gc_mark(void *ptr)
{
    memfd_wrapper *memfd = (memfd_wrapper *)ptr;
    if (memfd) {
        rb_gc_mark(memfd->name);
        rb_gc_mark(memfd->flags);
        rb_gc_mark(memfd->io);
    }
}

static inline size_t rb_memfd_memsize(const void *ptr)
{
  return sizeof(memfd_wrapper);
}

const rb_data_type_t memfd_type = {
  "memfd",
  {
    rb_memfd_gc_mark,
    rb_memfd_gc_free,
    rb_memfd_memsize
  },
  NULL, NULL, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE rb_memfd_s_new(int argc, VALUE *argv, VALUE mod)
{
    memfd_wrapper *memfd = NULL;
    VALUE fd;
    VALUE obj;

    rb_check_arity(argc, 0, 2);
    obj = TypedData_Make_Struct(rb_cMemfd, memfd_wrapper, &memfd_type, memfd);
    memfd->io = Qnil;
    memfd->region = NULL;
    memfd->size = 0;
    if (argc == 0) {
        memfd->name = rb_random_bytes(rb_const_get(rb_cRandom, rb_intern("DEFAULT")), 8);
        memfd->flags = INT2NUM((MFD_CLOEXEC | MFD_ALLOW_SEALING));
    } else if (argc == 1) {
        memfd->name = argv[0];
        memfd->flags = INT2NUM((MFD_CLOEXEC | MFD_ALLOW_SEALING));
    } else {
        memfd->name = argv[0];
        memfd->flags = argv[1];
    }
    Check_Type(memfd->name, T_STRING);
    Check_Type(memfd->flags, T_FIXNUM);
    memfd->fd = rb_memfd_syscall_memfd_create((const char *)RSTRING_PTR(memfd->name), (unsigned int)NUM2INT(memfd->flags));
    fd = INT2FIX(memfd->fd);
    memfd->io = rb_funcall2(rb_cIO, rb_intern("for_fd"), 1, &fd);
    rb_obj_call_init(obj, 0, NULL);
    return obj;
}

static VALUE rb_memfd_read(VALUE obj, VALUE fd, VALUE size)
{
  char * data;
  Check_Type(fd, T_FIXNUM);
  Check_Type(size, T_FIXNUM);
  data = mmap(NULL, (size_t)NUM2INT(size), PROT_READ, MAP_PRIVATE, NUM2INT(fd), 0);
  if (data == MAP_FAILED) rb_sys_fail("rb_memfd_read");
  return rb_str_new_cstr(data);
}

static VALUE rb_memfd_name(VALUE obj)
{
    GetMemfd(obj);
    return memfd->name;
}

static VALUE rb_memfd_flags(VALUE obj)
{
    GetMemfd(obj);
    return memfd->flags;
}

static VALUE rb_memfd_fd(VALUE obj)
{
    GetMemfd(obj);
    return INT2FIX(memfd->fd);
}

static VALUE rb_memfd_io(VALUE obj)
{
    GetMemfd(obj);
    return memfd->io;
}

static VALUE rb_memfd_map(VALUE obj, VALUE size, VALUE offset)
{
    int ret;
    GetMemfd(obj);
    memfd->size = (size_t)NUM2LONG(size);
    ret = ftruncate(memfd->fd, (off_t)memfd->size);
    if (ret == -1) {
        MemfdIOError("ftruncate");
    }
    memfd->region = mmap(NULL, (size_t)memfd->size, PROT_READ | PROT_WRITE, MAP_SHARED, memfd->fd, (uint64_t)NUM2INT(offset));
    if (memfd->region == MAP_FAILED) {
       MemfdAllocError("rb_memfd_map")
       return Qnil;
    }
    return obj;
}

static VALUE rb_memfd_unmap(int argc, VALUE *argv, VALUE obj)
{
    GetMemfd(obj);
    if (memfd->region != NULL) munmap(memfd->region, memfd->size);
    if (argc == 0 || (argc == 1 && argv[0] != Qfalse)) {
        if (memfd->fd != -1) {
           if (memfd->io != Qnil) rb_io_close(memfd->io);
           close(memfd->fd);
           memfd->fd = -1;
        }
    }
    return Qnil;
}

static VALUE rb_memfd_size(VALUE obj)
{
    struct stat stat;
    int ret;
    GetMemfd(obj);
    ret = fstat(memfd->fd, &stat);
    if (ret < 0) return INT2NUM(-errno);
    return INT2NUM(stat.st_size);
}

void Init_memfd_ext()
{
    rb_cMemfd = rb_define_class("Memfd", rb_cObject);
    rb_eMemfd = rb_define_class_under(rb_cMemfd, "Error", rb_eStandardError);

    rb_define_const(rb_cMemfd, "MFD_DEF_SIZE", INT2NUM(MFD_DEF_SIZE));

    rb_define_const(rb_cMemfd, "MFD_CLOEXEC", INT2NUM(MFD_CLOEXEC));
    rb_define_const(rb_cMemfd, "MFD_ALLOW_SEALING", INT2NUM(MFD_ALLOW_SEALING));

    rb_define_const(rb_cMemfd, "F_ADD_SEALS", INT2NUM(F_ADD_SEALS));
    rb_define_const(rb_cMemfd, "F_GET_SEALS", INT2NUM(F_GET_SEALS));
    rb_define_const(rb_cMemfd, "F_SEAL_SEAL", INT2NUM(F_SEAL_SEAL));
    rb_define_const(rb_cMemfd, "F_SEAL_SHRINK", INT2NUM(F_SEAL_SHRINK));
    rb_define_const(rb_cMemfd, "F_SEAL_GROW", INT2NUM(F_SEAL_GROW));
    rb_define_const(rb_cMemfd, "F_SEAL_WRITE", INT2NUM(F_SEAL_WRITE));

    // Server
    rb_define_singleton_method(rb_cMemfd, "new", rb_memfd_s_new, -1);
    rb_define_method(rb_cMemfd, "name", rb_memfd_name, 0);
    rb_define_method(rb_cMemfd, "flags", rb_memfd_flags, 0);
    rb_define_method(rb_cMemfd, "fd", rb_memfd_fd, 0);
    rb_define_method(rb_cMemfd, "size", rb_memfd_size, 0);
    rb_define_method(rb_cMemfd, "io", rb_memfd_io, 0);
    rb_define_alias(rb_cMemfd,  "to_io", "io");
    rb_define_method(rb_cMemfd, "map", rb_memfd_map, 2);
    rb_define_method(rb_cMemfd, "unmap", rb_memfd_unmap, -1);
    rb_define_alias(rb_cMemfd,  "close", "unmap");

    // Client
    rb_define_singleton_method(rb_cMemfd, "read", rb_memfd_read, 2);
}