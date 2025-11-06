CPU_CORES ?= $(shell echo $$(($$(nproc) - 2)))

LINUX_DIR := ./linux
BUILDROOT_DIR := ./buildroot

KERNEL_IMG := $(LINUX_DIR)/arch/x86/boot/bzImage
RFS_IMG := $(BUILDROOT_DIR)/output/images/rootfs.ext2

QEMU_CMD := qemu-system-x86_64 \
    -kernel $(KERNEL_IMG) \
    -hda $(RFS_IMG) \
    -append "root=/dev/sda console=ttyS0" \
    -drive file=nvme_disk.img,if=none,id=D22 \
    -device nvme,drive=D22,serial=1234 \
    -m 2G

MAKE_CMD := PATH=/usr/bin:/bin:/usr/sbin:/sbin $(MAKE)

.PHONY: all kernel boot help clean-kernel

kernel:
	@echo "--- Building Kernel ---"
	@$(MAKE_CMD) -C $(LINUX_DIR) -j$(CPU_CORES)

boot: $(KERNEL_IMG) $(RFS_IMG)
	@echo "--- Starting QEMU ---"
	@$(QEMU_CMD)

help:
	@echo "========================================================"
	@echo " To test your driver inside QEMU, run these commands:"
	@echo "========================================================"
	@echo " # 1. Create a 1MB test file"
	@echo " dd if=/dev/zero of=original.bin bs=1M count=1"
	@echo ""
	@echo " # 2. Write the file to the NVMe device"
	@echo " dd if=original.bin of=/dev/nvme0n1"
	@echo ""
	@echo " # 3. Read the data back from the device"
	@echo " dd if=/dev/nvme0n1 of=readback.bin bs=1M count=1"
	@echo ""
	@echo " # 4. Compare the original and read-back files"
	@echo " cmp original.bin readback.bin"
	@echo ""
	@echo " If 'cmp' produces no output, the test is SUCCESSFUL!"
	@echo "========================================================"


clean-kernel:
	@$(MAKE_CMD) -C $(LINUX_DIR) clean
