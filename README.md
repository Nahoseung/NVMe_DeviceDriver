### QEMU 기반의 기본 NVMe 드라이버 개발

QEMU 가상 환경에서 NVMe 스토리지 컨트롤러 블록 디바이스 드라이버 개발

---

#### ** 프로젝트 구조 **
* 커널 소스 트리 내 `drivers/nvme/my_nvme/` 경로에 프로젝트 디렉터리를 생성
* `my_nvme.c`, `Makefile`, `Kconfig` 파일을 생성하여 커널 빌드 시스템에 새로운 드라이버 모듈을 통합
* `my_nvme.c`에 QEMU의 가상 NVMe 장치(Vendor: 0x1b36, Device: 0x0010)를 인식하는 `pci_driver` 코드를 작성


#### **빌드 및 테스트 방법**

1.  **커널 설정 변경 (`make menuconfig`)**
    * `linux` 디렉터리에서 `make menuconfig` 실행 및 NVMe 제외

2.  **커널 컴파일**
    * 루트에서 `make kernel` 실행

3.  **QEMU 실행**
    * `make boot` 실행

4.  **QEMU 내부에서 테스트**
    * `root`로 로그인 후 `make test` 동작 검증

#### TEST1
dd if=/dev/random of=origin.bin bs=1M count=1

Write
dd if=origin.bin of=/dev/nvme0n1

Read
dd if=/dev/nvme0n1 of=readback.bin bs=1M count=1

Compare 
cmp origin.bin readback.bin

#### TEST2
echo "[WRITE SOMETHING]" > origin.txt
SIZE = $(wc -c < origin.txt)

dd if=origin.txt of=/dev/nvme0n1
dd if=/dev/nvme0n1 of=readback.txt bs=1 count=$SIZE
cmp origin.txt readback.txt
cat readback.txt


#### Info

# lspci -nn
00:01.0 Class 0601: 8086:7000

##### 00:04.0 Class 0108: 1b36:0010

00:01.0 Class 0600: 8086:1237
00:01.3 Class 0680: 8086:7113
00:03.0 Class 0200: 8086:100e
00:01.1 Class 0101: 8086:7010
00:02.0 Class 0300: 1234:1111
#

##### ** ToDo **

* [ ] **PCIe BAR 매핑**: `my_nvme_probe` 함수에서 `ioremap`을 사용하여 컨트롤러의 레지스터 메모리(BAR0)에 접근
* [ ] **컨트롤러 초기화**: 매핑된 레지스터를 통해 NVMe 컨트롤러를 비활성화(`CC.EN=0`), 초기화, 재활성화(`CC.EN=1`)로직 구현
* [ ] **Admin Queue 생성**: 관리자용 제출 큐(SQ)와 완료 큐(CQ)를 메모리에 할당하고, 해당 큐의 물리 주소를 컨트롤러 레지스터(ASQ, ACQ, AQA)에 등록
* [ ] **I/O Queue 생성 및 블록 디바이스 연동**: `blk-mq` 프레임워크를 사용하여 I/O 큐를 생성하고, `/dev/nvme0n1` 장치를 생성하여 리눅스 블록 시스템과 연결
