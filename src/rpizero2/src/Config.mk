RASPPI = 3
AARCH = 64
DEFINE += -DARM_ALLOW_MULTI_CORE
DEFINE += -DKERNEL_MAX_SIZE=67108864
DEFINE += -DUSE_FATFS=1
DEFINE += -DFF_FS_EXFAT=0
PREFIX64 = aarch64-none-elf-
