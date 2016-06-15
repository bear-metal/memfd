# Memfd

* http://github.com/bear-metal/memfd

## Status

[![Travis Build Status](https://travis-ci.org/bear-metal/memfd.svg?branch=master)](https://travis-ci.org/bear-metal/memfd)

## Description

Memfd is a wrapper around the `memfd_create` system call which creates an anonymous memory-backed file and returns a file descriptor reference to it. It provides a simple alternative to manually mounting a `tmpfs` filesystem and creating and opening a file in that filesystem. The file is a regular file on a kernel-internal filesystem and thus supports most operations such as `ftruncate(2)`, `read(2)`, `dup(2)`, `mmap(2)` etc.

Imagine that `malloc(3)` returns a file descriptor instead of a pointer. The system call also introduced a new feature called "file sealing". With file sealing you can specify to the kernel that the file backed by anonymous memory has certain restrictions such as: no writes occur to the file, and the file size does not shrink or grow. For IPC based servers the `F_SEAL_SHRINK` seal is of interest ask the server can be sure clients won't shrink it's buffers and can read files without side effects of unexpected shrinking.

## Use cases

* Shared memory buffers don't require a mount point or having to create files on the filesystem soley to use as shared memory.
* An alternative to creating files in `/tmp` if there's never an intention to actually link the file in the filesystem.
* Zero-copy transfer of large objects through IPC: one process creates a shared memory object and just passes the file descriptor to a remote process.
* Preventing specific operations on a file through the file sealing API.
* Better server stability and less risk of unexpected SIGBUS due to unexpected client buffer alterations.

## Installation

Linux ONLY!

```
gem install memfd
```

## Synopsis

TODO

```ruby
#! /usr/bin/env ruby

require 'memfd'

```


## Requirements

* Ruby 2.1.0 or higher, including any development packages necessary
  to compile native extensions.

* A Linux Kernel version > 3.17

## Development

```bash
  bundle install
  bundle exec rake
```

## License

MIT. See the `LICENSE.txt` file.