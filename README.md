# QEMU 기반의 기본 NVMe 드라이버 개발 프로젝트

QEMU 가상 환경에서 NVMe 스토리지 컨트롤러를 대상으로 하는 기본적인 리눅스 블록 디바이스 드라이버 개발



**프로젝트 구조 설정**
    * 커널 소스 트리 내 `drivers/nvme/my_nvme/` 경로에 프로젝트 디렉터리를 생성
    * `my_nvme.c`, `Makefile`, `Kconfig` 파일을 생성하여 커널 빌드 시스템에 새로운 드라이버 모듈을 통합


    * `my_nvme.c`에 QEMU의 가상 NVMe 장치(Vendor: 0x1b36, Device: 0x0010)를 인식하는 `pci_driver` 뼈대 코드를 작성
    * `probe` 함수가 호출될 때 커널 로그(`dmesg`)에 환영 메시지를 출력하는 기능을 구현

