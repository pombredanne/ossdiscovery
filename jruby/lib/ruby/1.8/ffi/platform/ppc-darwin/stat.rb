# This file is generated by rake. Do not edit.

module Platform
  module Stat
    class Stat < FFI::Struct
      self.size = 108
      layout :st_dev, :dev_t, 0,
             :st_ino, :ino_t, 8,
             :st_nlink, :nlink_t, 6,
             :st_mode, :mode_t, 4,
             :st_uid, :uid_t, 16,
             :st_gid, :gid_t, 20,
             :st_size, :off_t, 60,
             :st_blocks, :blkcnt_t, 68,
             :st_atime, :time_t, 28,
             :st_mtime, :time_t, 36,
             :st_ctime, :time_t, 44






    end
    module Constants
      S_IEXEC = 0x40
      S_IREAD = 0x100
      S_IRGRP = 0x20
      S_IROTH = 0x4
      S_IRUSR = 0x100
      S_IRWXG = 0x38
      S_IRWXO = 0x7
      S_IRWXU = 0x1c0
      S_ISGID = 0x400
      S_ISUID = 0x800
      S_IWGRP = 0x10
      S_IWOTH = 0x2
      S_IWRITE = 0x80
      S_IWUSR = 0x80
      S_IXGRP = 0x8
      S_IXOTH = 0x1
      S_IXUSR = 0x40







    end
    include Constants
  end
end
