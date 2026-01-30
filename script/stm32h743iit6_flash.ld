/* 程序入口 */
ENTRY(Reset_Handler)

/* Flash和RAM内存区域划分 */
MEMORY
{
  ITCMRAM     (xrw) : ORIGIN = 0x00000000, LENGTH = 64K   /* ITCMRAM */

  BOOTLOADER  (rx)  : ORIGIN = 0x08000000, LENGTH = 64K   /* 启动加载器 */
  PARAMS      (rx)  : ORIGIN = 0x08010000, LENGTH = 4K    /* 启动参数 */
  PATCH       (rx)  : ORIGIN = 0x08011000, LENGTH = 380K  /* 差分包 */
  APP_A       (rx)  : ORIGIN = 0x08070000, LENGTH = 800K  /* App_A */
  APP_B       (rx)  : ORIGIN = 0x08138000, LENGTH = 800K  /* App_B */

  DTCMRAM     (xrw) : ORIGIN = 0x20000000, LENGTH = 128K  /* DTCMRAM */
  RAM_D1      (xrw) : ORIGIN = 0x24000000, LENGTH = 512K  /* RAM_D1 */
  RAM_D2      (xrw) : ORIGIN = 0x30000000, LENGTH = 288K  /* RAM_D2 */
  RAM_D3      (xrw) : ORIGIN = 0x38000000, LENGTH = 64K   /* RAM_D3 */
}

/* 栈底值：指向DTCMRAM的末尾 */
stack_init_val = ORIGIN(DTCMRAM) + LENGTH(DTCMRAM);

/* 栈大小检查：如果RAM不足会报错 */
stack_size_min = 0x200;  /* 留给MSP（中断栈）的最小空间 */

SECTIONS
{
  /* 1. 中断向量表：必须放在Flash起始位置 */
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
  } > BOOTLOADER

  /* 2. 代码段：存放程序指令 */
  .text :
  {
    . = ALIGN(4);
    *(.text)      /* 所有的.text段 */
    *(.text*)     /* 所有的.text*段 */
    *(.glue_7)    /* ARM/Thumb胶水代码 */
    *(.glue_7t)
    *(.eh_frame)

    . = ALIGN(4);
    _text_end = .;   /* 代码段结束地址 */
  } > BOOTLOADER

  /* 3. 只读数据段：常量、字符串 */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
  } > BOOTLOADER

  /* --- 以下数据将放入RAM --- */

  /* 用于启动代码将数据从Flash复制到RAM */
  _data_flash_addr = LOADADDR(.data);

  /* 5. 已初始化数据段 */
  .data :
  {
    . = ALIGN(4);
    _data_ram_addr = .; /* RAM中的起始地址 */
    *(.data)
    *(.data*)
    *(.ram_fn)          /* 如果有需要在RAM运行的函数 */
    *(.ram_fn*)

    . = ALIGN(4);
    _data_ram_end = .;  /* RAM中的结束地址 */
  } > DTCMRAM AT > BOOTLOADER

  /* 6. 未初始化数据段 */
  .bss :
  {
    . = ALIGN(4);
    _bss_ram_addr = .;  /* RAM中的起始地址 */
    *(.bss)
    *(.bss*)

    . = ALIGN(4);
    _bss_ram_end = .;   /* RAM中的结束地址 */
  } > DTCMRAM

  /* 7. 堆栈空间检查段 (不占用实际空间，仅用于链接器检查RAM是否溢出) */
  .msp_stack :
  {
    . = ALIGN(8);
    . = . + stack_size_min;
    . = ALIGN(8);
  } > DTCMRAM

  /* 8. 显式丢弃的内容 */
  /DISCARD/ :
  {
    /* 丢弃 C++ 异常回溯表 */
    *(.ARM.extab* .gnu.linkonce.armextab.*)
    *(.ARM.exidx*)

    /* 丢弃编译器自带的 TLS 占位符 */
    *(.tdata*)
    *(.tbss*)

    /* 丢弃标准库里的调试注释等 */
    libc.a:* (*)
    libm.a:* (*)
    libgcc.a:* (*)
  }
}