### QEMU 기반의 기본 NVMe 드라이버 개발

QEMU 가상 환경에서 NVMe 스토리지 컨트롤러 블록 디바이스 드라이버 개발

---

#### 프로젝트 개요
* `drivers/nvme/my_nvme/` 경로에 프로젝트 디렉터리 생성
* `my_nvme.c`에 QEMU의 가상 NVMe 장치(Vendor: 0x1b36, Device: 0x0010) 인식하는 `pci_driver` 코드 작성


#### 테스트

1.  **커널 설정 변경 (`make menuconfig`)**
    * `linux` 디렉터리에서 `make menuconfig` 실행 및 NVMe 제외

2.  **커널 컴파일**
    * 루트에서 `make kernel`

3.  **QEMU 실행**
    * `make boot`

4.  **QEMU 내부에서 테스트**
    * `root`로 로그인 후 아래의 Test 동작 검증

### TEST1
dd if=/dev/random of=origin.bin bs=1M count=1

##### Write
dd if=origin.bin of=/dev/my_nvme0n1

##### Read
dd if=/dev/my_nvme0n1 of=readback.bin bs=1M count=1

##### Compare 
cmp origin.bin readback.bin

#### TEST2
echo "[WRITE SOMETHING]" > origin.txt
SIZE = $(wc -c < origin.txt)

dd if=origin.txt of=/dev/my_nvme0n1
dd if=/dev/my_nvme0n1 of=readback.txt bs=1 count=$SIZE
cmp origin.txt readback.txt
cat readback.txt




##### lspci -nn
00:01.0 Class 0601: 8086:7000

##### 00:04.0 Class 0108: 1b36:0010

00:01.0 Class 0600: 8086:1237
00:01.3 Class 0680: 8086:7113
00:03.0 Class 0200: 8086:100e
00:01.1 Class 0101: 8086:7010
00:02.0 Class 0300: 1234:1111
#

# DataSheet Spec

## NVMe Controller Property Definition (Figure 35; Page: 58)
### BAR
| Offset (h) | Size (bytes) | I/O Ctrl | Admin Ctrl | Discovery Ctrl | Name / Description |
|-------------|--------------|-----------|--------------|----------------|--------------------|
| 00h | 8 | M | M | M | **CAP:** Controller Capabilities |
| 08h | 4 | M | M | M | **VS:** Version |
| 0Ch | 4 | M² | M² | R | **INTMS:** Interrupt Mask Set |
| 0Fh | 4 | M² | M² | R | **INTMC:** Interrupt Mask Clear |
| 14h | 4 | M | M | M | **CC:** Controller Configuration |
| 18h | – | R | R | R | Reserved |
| 1Ch | 4 | M | M | M | **CSTS:** Controller Status |
| 20h | 4 | O | O | R | **NSSR:** NVM Subsystem Reset |
| 24h | 4 | M² | M² | R | **AQA:** Admin Queue Attributes |
| 28h | 8 | M² | M² | R | **ASQ:** Admin Submission Queue Base Address |
| 30h | 8 | M² | M² | R | **ACQ:** Admin Completion Queue Base Address |
| 38h | 4 | O³ | O³ | R | **CMBLOC:** Controller Memory Buffer Location |
| 3Ch | 4 | O³ | O³ | R | **CMBSZ:** Controller Memory Buffer Size |
| 40h | 4 | O³ | O³ | R | **BPINFO:** Boot Partition Information |
| 44h | 4 | O³ | O³ | R | **BPRSEL:** Boot Partition Read Select |
| 48h | 8 | O³ | O³ | R | **BPMBL:** Boot Partition Memory Buffer Location |
| 50h | 8 | O³ | O³ | R | **CMBMSC:** Controller Memory Buffer Memory Space Control |
| 58h | 4 | O³ | O³ | R | **CMBSTS:** Controller Memory Buffer Status |
| 5Ch | 4 | O³ | O³ | R | **CMBEBS:** Controller Memory Buffer Elasticity Buffer Size |
| 60h | 4 | O³ | O³ | R | **CMBSWTP:** Controller Memory Buffer Sustained Write Throughput |
| 64h | 4 | O | O | R | **NSSD:** NVM Subsystem Shutdown |
| 68h | 4 | M | M | R | **CRTO:** Controller Ready Timeouts |
| 6Ch | – | R | R | R | Reserved |
| E00h | 4 | O³ | O³ | R | **PMRCAP:** Persistent Memory Capabilities |
| E04h | 4 | O³ | O³ | R | **PMRCTL:** Persistent Memory Region Control |
| E08h | 4 | O³ | O³ | R | **PMRSTS:** Persistent Memory Region Status |
| E0Ch | 4 | O³ | O³ | R | **PMREBS:** Persistent Memory Region Elasticity Buffer Size |
| E10h | 4 | O³ | O³ | R | **PMRSWTP:** Persistent Memory Region Sustained Write Throughput |
| E14h | 4 | O³ | O³ | R | **PMRMSCL:** Persistent Memory Region Controller Memory Space Control Lower |
| E18h | 4 | O³ | O³ | R | **PMRMSCU:** Persistent Memory Region Controller Memory 

---

CAP: 0x000000040001000f
The stride is specified as (2 ^ (2 + DSTRD)) in bytes. 
## Memory-based Transport Queue Model
3.3.1.1
Queue Setup and Initialization
To setup and initialize I/O Submission Queues and I/O Completion Queues for use, host software follows
these steps:
1. Configures the Admin Submission and Completion Queues by initializing the Admin Queue
Attributes (AQA), Admin Submission Queue Base Address (ASQ), and Admin Completion Queue
Base Address (ACQ) properties appropriately;
2. Configures the size of the I/O Submission Queues (CC.IOSQES) and I/O Completion Queues
(CC.IOCQES);
3. Submits a Set Features command with the Number of Queues attribute set to the requested
number of I/O Submission Queues and I/O Completion Queues. The completion queue entry for
this Set Features command indicates the number of I/O Submission Queues and I/O Completion
Queues allocated by the controller;
4. Determines the maximum number of entries supported per queue (CAP.MQES) and whether the
queues are required to be physically contiguous (CAP.CQR);
5. Creates I/O Completion Queues within the limitations of the number allocated by the controller and
the queue attributes supported (maximum entries and physically contiguous requirements) by using
the Create I/O Completion Queue command; and
6. Creates I/O Submission Queues within the limitations of the number allocated by the controller and
the queue attributes supported (maximum entries and physically contiguous requirements) by using
the Create I/O Submission Queue command.
At the end of this process, I/O Submission Queues and I/O Completion Queues have been setup and
initialized and may be used to complete I/O commands.


## NVMe Submission Queue Entry — Common Command Format

| Offset / Bits | Description |
|---------------|-------------|
| **CDW0 (Bytes 03:00)** | **Command Dword 0 (CDW0): This field is common to all commands and is defined below.** |
| **31:16** | **Command Identifier (CID):** This field specifies a unique identifier for the command when combined with the Submission Queue identifier. The value of FFFFh should not be used as the Error Information log page uses this value to indicate an error is not associated with a particular command. |
| **15:14** | **PRP or SGL for Data Transfer (PSDT):** This field specifies whether PRPs or SGLs are used for any data transfer associated with the command. PRPs shall be used for all Admin commands for NVMe over PCIe implementations. SGLs shall be used for all Admin and I/O commands for NVMe over Fabrics implementations (i.e., this field set to 01b). <br><br>**Value / Definition** <br>• 00b — PRPs are used for this transfer. <br>• 01b — SGLs are used for this transfer. If used, Metadata Pointer (MPTR) contains an address of a single contiguous physical buffer that is byte aligned. <br>• 10b — SGLs are used for this transfer. If used, Metadata Pointer (MPTR) contains an address of an SGL segment containing exactly one SGL Descriptor that is qword aligned. <br>• 11b — Reserved <br><br>If there is metadata that is not interleaved with the user data, as specified in the Format NVM command, then the Metadata Pointer (MPTR) field is used to point to the metadata. |
| **13:10** | Reserved |
| **09:08** | **Fused Operation (FUSE):** In a fused operation, a complex command is created by “fusing” together two simpler commands. **Value / Definition** <br>• 00b — Normal operation <br>• 01b — Fused operation, first command <br>• 10b — Fused operation, second command <br>• 11b — Reserved |
| **07:00** | **Opcode (OPC):** This field specifies the opcode of the command to be executed. |
| **Bytes 07:04** | **Namespace Identifier (NSID):** This field specifies the namespace that this command applies to. If the namespace identifier is not used for the command, then this field shall be cleared to 0h. The value FFFFFFFFh in this field is a broadcast value where the scope is dependent on the command. Specifying an inactive or invalid namespace identifier may cause the controller to abort the command with an appropriate status code. |
| **Bytes 11:08** | **Command Dword 2 (CDW2):** This field is command specific Dword2. |
| **Bytes 15:12** | **Command Dword 3 (CDW3):** This field is command specific Dword3. |
| **Bytes 23:16** | **Metadata Pointer (MPTR):** If CDW0.PSDT is cleared to 00b, this field contains the address of a contiguous physical buffer of metadata (DWORD aligned). If CDW0.PSDT is set to 01b or 10b, this field contains an SGL segment address depending on alignment rules. |
| **Bytes 39:24 — Data Pointer (DPTR)** | **Definition depends on CDW0.PSDT:** |
| **If CDW0.PSDT = 00b (PRP mode)** |  |
| **39:32** | **PRP Entry 2 (PRP2):** Reserved if the data transfer does not cross a memory page boundary; otherwise specifies the Page Base Address of the second memory page or a PRP List pointer depending on transfer size and alignment. |
| **31:24** | **PRP Entry 1 (PRP1):** Contains the first PRP entry for the command or a PRP List pointer depending on the command. |
| **If CDW0.PSDT = 01b or 10b (SGL mode)** |  |
| **39:24** | **SGL Entry 1 (SGL1):** Contains the first SGL segment for the command. If the SGL segment is an SGL Data Block, Keyed SGL Data Block, or Transport SGL Data Block descriptor, then it describes the entire data transfer. |
| **Bytes 43:40** | **Command Dword 10 (CDW10):** This field is command specific Dword 10. |
| **Bytes 47:44** | **Command Dword 11 (CDW11):** This field is command specific Dword 11. |
| **Bytes 51:48** | **Command Dword 12 (CDW12):** This field is command specific Dword 12. |
| **Bytes 55:52** | **Command Dword 13 (CDW13):** This field is command specific Dword 13. |
| **Bytes 59:56** | **Command Dword 14 (CDW14):** This field is command specific Dword 14. |
| **Bytes 63:60** | **Command Dword 15 (CDW15):** This field is command specific Dword 15. |


## Figure 138: Opcodes for Admin Commands
| (07) Generic Command | (06:02) Function | (01:00) Data Transfer | Combined Opcode | Command                       |
|----------------------|------------------|------------------------|------------------|-------------------------------|
| 0b                   | 000 00b          | 00b                   | 00h             | Delete I/O Submission Queue   |
| 0b                   | 000 00b          | 01b                   | 01h             | Create I/O Submission Queue   |
| 0b                   | 000 00b          | 10b                   | 02h             | Get Log Page                  |
| 0b                   | 000 01b          | 00b                   | 04h             | Delete I/O Completion Queue   |
| 0b                   | 000 01b          | 01b                   | 05h             | Create I/O Completion Queue   |
| 0b                   | 000 01b          | 10b                   | 06h             | Identify                      |
| 0b                   | 000 10b          | 00b                   | 08h             | Abort                         |
| 0b                   | 000 10b          | 01b                   | 09h             | Set Features                  |
| 0b                   | 000 10b          | 10b                   | 0Ah             | Get Features                  |
| 0b                   | 000 11b          | 00b                   | 0Ch             | Asynchronous Event Request    |
| 0b                   | 000 11b          | 01b                   | 0Dh             | Namespace Management          |
| 0b                   | 001 00b          | 00b                   | 10h             | Firmware Commit               |
| 0b                   | 001 00b          | 01b                   | 11h             | Firmware Image Download       |
| 0b                   | 001 01b          | 00b                   | 14h             | Device Self-test              |
| 0b                   | 001 01b          | 01b                   | 15h             | Namespace Attachment          |
| 0b                   | 001 10b          | 00b                   | 18h             | Keep Alive                    |
| 0b                   | 001 10b          | 01b                   | 19h             | Directive Send                |
| 0b                   | 001 10b          | 10b                   | 1Ah             | Directive Receive             |
| 0b                   | 001 11b          | 00b                   | 1Ch             | Virtualization Management     |
| 0b                   | 001 11b          | 01b                   | 1Dh             | NVMe-MI Send                  |
| 0b                   | 001 11b          | 10b                   | 1Eh             | NVMe-MI Receive               |
| 0b                   | 010 00b          | 00b                   | 20h             | Capacity Management           |
| 0b                   | 010 01b          | 00b                   | 24h             | Lockdown                      |
| 0b                   | 111 11b          | 00b                   | 7Ch             | Doorbell Buffer Config        |
| 0b                   | 111 11b          | 11b                   | 7Fh             | Fabrics Commands              |
| 1b                   | 000 00b          | 00b                   | 80h             | Format NVM                    |
| 1b                   | 000 00b          | 01b                   | 81h             | Security Send                 |
| 1b                   | 000 00b          | 10b                   | 82h             | Security Receive              |
| 1b                   | 000 01b          | 00b                   | 84h             | Sanitize                      |
| 1b                   | 000 01b          | 10b                   | 86h             | Get LBA Status (NVM, ZNS)     |

The Identify command returns a data buffer that describes information about the NVM subsystem, the
domain, the controller or the namespace(s). The data structure is 4,096 bytes in size.
The Identify command uses the Data Pointer, Command Dword 10, Command Dword 11, and Command
Dword 14 fields. All other command specific fields are reserved.

## Doorbell
The PCIe transport supports Controller Properties as memory mapped registers that are located in the
address range specified in the MLBAR/MUBAR registers (PCI BAR0 and BAR1). NVM Express defined
registers for the PCI Express transport start at the offset defined in Figure 4. All controller registers shall be
mapped to a memory space that supports in-order access and variable access widths. For many computer
architectures, specifying the memory space as uncacheable produces this behavior. The host shall not
issue locked accesses to registers. The host shall access registers in their native width or aligned 32-bit
accesses. Violation of either of these host requirements results in undefined behavior.
Accesses that target any portion of two or more registers are not supported.
All reserved registers and all reserved bits within registers are read-only and return 0h when read.
Figure 4: PCI Express Specific Controller Property Definitions


##### ** ToDo **
* [ * ] **PCIe BAR 매핑**: `my_nvme_probe` 함수에서 `ioremap`을 사용하여 컨트롤러의 레지스터 메모리(BAR0)에 접근
* [ * ] **컨트롤러 초기화**: 매핑된 레지스터를 통해 NVMe 컨트롤러를 비활성화(`CC.EN=0`), 초기화, 재활성화(`CC.EN=1`)로직 구현
* [ * ] **Admin Queue 생성**: 관리자용 제출 큐(SQ)와 완료 큐(CQ)를 메모리에 할당하고, 해당 큐의 물리 주소를 컨트롤러 레지스터(ASQ, ACQ, AQA)에 등록
* [ ] **I/O Queue 생성 및 블록 디바이스 연동**: `blk-mq` 프레임워크를 사용하여 I/O 큐를 생성하고, `/dev/nvme0n1` 장치를 생성하여 리눅스 블록 시스템과 연결
