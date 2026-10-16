# powerpcu_j_install

ระบบช่วยติดตั้งโปรแกรม jhcis

## สิ่งที่ต้องการ

ผมต้องการให้คุณช่วยสร้างโปรแกรม ช่วยในการติดตั้งโปรแกรม jhcis โดยศึกษาไฟล์จาก JHCIS-install-jre_jdk_64

## Goal

* โปรแกรมนี้จะทำการติดตั้งเฉพาะเครื่องลูกเท่านั้น ไม่ทำในเครื่องแม่
* ช่วยในการ อัปเดท permission ในโฟลเดอร์ที่ติดตั้ง
* ค้นหา ip และ port ในวงแลนของเครื่องแม่อัตโนมัติ
  * default port 3333 pass 123456 mysql 5.6.45
* ถาม user ว่าต้องการอัปเดท version ใหม่ไหม
  * yes อัปเดทให้

## Build

ไฟล์ติดตั้งของ JHCIS ไม่ได้เก็บใน git ให้ดาวน์โหลดจาก <https://jhcis.moph.go.th/download/> แล้ววางตาม path นี้:

```
JHCIS-install-jre_jdk_64/jHCIS-All-PCU/jhcis-install-client-jre8-0-191_64.exe
JHCIS_Update.exe
```

จากนั้น:

```
bun install
bun run build   # → dist/jhcis-installer.exe
```
