
# QEMU 기반 리눅스 NVMe 드라이버 개발

QEMU 환경에서 NVMe 컨트롤러용 리눅스 블록 디바이스 드라이버를 구현

---

## 1. 프로젝트 개요

- `drivers/nvme/my_nvme/` 경로에 NVMe 드라이버 코드 추가  
- `my_nvme.c`에서 QEMU 가상 NVMe 장치  
  - Vendor ID: 0x1b36  
  - Device ID: 0x0010  
  를 인식하는 `pci_driver` 작성  
- BAR0를 매핑해 NVMe 레지스터 직접 접근  
- Admin Queue 생성 후 Identify 명령 수행  
- I O Queue 생성 후 blk mq 기반으로 `/dev/my_nvme0n1` 블록 디바이스 등록

---

## 2. 빌드 및 실행

### 2.1 커널 설정 변경

    cd linux
    make menuconfig


*기본 NVMe 드라이버 비활성화

### 2.2 커널 빌드

    make kernel


### 2.3 QEMU 실행

    make boot


### 2.4 QEMU 내부 테스트

* root 로그인 후 아래 테스트 수행

---

## 3. 테스트

### TEST1 

    dd if=/dev/random of=origin_4k.bin bs=4K count=1
    dd if=origin_4k.bin of=/dev/my_nvme0n1 bs=4K count=1
    dd if=/dev/my_nvme0n1 of=readback_4k.bin bs=4K count=1
    cmp origin_4k.bin readback_4k.bin

### TEST 2 

    echo "[WRITE SOMETHING]" > origin.txt
    SIZE=$(wc -c < origin.txt)

    dd if=origin.txt of=/dev/my_nvme0n1
    dd if=/dev/my_nvme0n1 of=readback.txt bs=1 count=$SIZE

    cmp origin.txt readback.txt
    cat readback.txt

### TEST3 멀티 세그먼트 테스트
    dd if=/dev/random of=origin.bin bs=1M count=1
    dd if=origin.bin of=/dev/my_nvme0n1
    dd if=/dev/my_nvme0n1 of=readback.bin bs=1M count=1
    cmp origin.bin readback.bin

---

## 4. QEMU 내부 PCI 정보

```
00:01.0 Class 0601: 8086:7000
00:01.0 Class 0600: 8086:1237
00:01.3 Class 0680: 8086:7113
00:03.0 Class 0200: 8086:100e
00:01.1 Class 0101: 8086:7010
00:02.0 Class 0300: 1234:1111
00:04.0 Class 0108: 1b36:0010   ← NVMe
```

---

## 5. NVMe 컨트롤러 BAR0 레지스터 구조


| Offset(h) | Size | Name   | 설명                                |
| --------- | ---- | ------ | --------------------------------- |
| 00h       | 8    | CAP    | Controller Capabilities           |
| 08h       | 4    | VS     | Version                           |
| 0Ch       | 4    | INTMS  | Interrupt Mask Set                |
| 0Fh       | 4    | INTMC  | Interrupt Mask Clear              |
| 14h       | 4    | CC     | Controller Configuration          |
| 1Ch       | 4    | CSTS   | Controller Status                 |
| 24h       | 4    | AQA    | Admin Queue Attributes            |
| 28h       | 8    | ASQ    | Admin SQ Base Address             |
| 30h       | 8    | ACQ    | Admin CQ Base Address             |
| 38h       | 4    | CMBLOC | Controller Memory Buffer Location |
| 3Ch       | 4    | CMBSZ  | Controller Memory Buffer Size     |




        CAP = 0x000000040001000f

        Doorbell stride = 2^(2 + DSTRD)

---

## 6. Queue 초기화 

메모리 기반 Queue 모델 기준

1. Admin SQ/CQ 메모리 할당

   * AQA ASQ ACQ 레지스터 설정
2. CC.IOCQES CC.IOSQES로 큐 엔트리 크기 지정
3. Set Features로 I O 큐 개수 요청
4. CAP.MQES CAP.CQR 확인
5. Create I O Completion Queue 명령
6. Create I O Submission Queue 명령


---


## 7. Admin 명령 Opcode

| Opcode | 기능            |
| ------ | ------------- |
| 00h    | Delete I O SQ |
| 01h    | Create I O SQ |
| 05h    | Create I O CQ |
| 06h    | Identify      |
| 09h    | Set Features  |
| 0Ah    | Get Features  |

---

## 8. 진행 상황

* [x] BAR 매핑
* [x] 컨트롤러 초기화 (CC.EN 조작 CSTS.RDY 폴링)
* [x] Admin Queue 생성
* [x] Identify Controller/Namespace
* [x] IO Queue 생성
* [x] blk mq 연동 후 `/dev/my_nvme0n1` 생성
* [x] dd cmp로 read write 검증 완료

## 9.TBD

- [] 크기가 큰 I/O 요청 대응 (멀티 세그먼트 PRP 매핑)

        현재 구현은 첫 번째 하나의 세그먼트만 PRP로 연결
        멀티 세그먼트 BIO 처리 시 PRP2 및 PRP List 생성 필요


```
```
