PROG = firmware

PROJECT_ROOT_PATH = $(realpath $(CURDIR)/../..)
DOCKER ?= docker run --rm -v $(PROJECT_ROOT_PATH):$(PROJECT_ROOT_PATH) -w $(CURDIR) mdashnet/armgcc

CFLAGS = -std=gnu99 -DCPU_MIMXRT1021DAG5A -DCPU_MIMXRT1021DAG5A_cm7 -DFSL_SDK_ENABLE_DRIVER_CACHE_CONTROL=1 -DXIP_BOOT_HEADER_DCD_ENABLE=1 -DSKIP_SYSCLK_INIT -DDATA_SECTION_IS_CACHEABLE=1 -DSDK_DEBUGCONSOLE=0 -DXIP_EXTERNAL_FLASH=1 -DXIP_BOOT_HEADER_ENABLE=1 -DFSL_FEATURE_PHYKSZ8081_USE_RMII50M_MODE -DUSE_RTOS=1 -DPRINTF_ADVANCED_ENABLE=1 -DLWIP_DISABLE_PBUF_POOL_SIZE_SANITY_CHECKS=1 -DSERIAL_PORT_TYPE_UART=1 -DSDK_OS_FREE_RTOS -DMCUXPRESSO_SDK -DMG_ARCH=MG_ARCH_FREERTOS -DMG_ENABLE_LWIP=1 -DCR_INTEGER_PRINTF -DPRINTF_FLOAT_ENABLE=0 -D__MCUXPRESSO -D__USE_CMSIS -DDEBUG -D__NEWLIB__ -O0 -fno-common -g3 -c -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fmerge-constants -fmacro-prefix-map="../$(@D)/"=. -mcpu=cortex-m7 -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb

LINKFLAGS = -nostdlib -Xlinker --gc-sections -Xlinker --sort-section=alignment -mcpu=cortex-m7 -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -T evkmimxrt1020_lwip_tcpecho_freertos_Debug.ld

SOURCES = $(shell find $(CURDIR) -type f -name '*.c' -not -path "*/doc/*")
OBJECTS = $(SOURCES:%.c=build/%.o)

INCLUDES = $(addprefix -I, $(shell find $(CURDIR) -type d -not -name 'build'))

build: $(PROG).bin

$(PROG).bin: $(PROG).axf
	@$(DOCKER) arm-none-eabi-size $<
	@$(DOCKER) arm-none-eabi-objcopy -v -O binary $< $@

$(PROG).axf: $(OBJECTS)
	$(info LD $@)
	@$(DOCKER) arm-none-eabi-gcc $(LINKFLAGS) -L"./ld" $(OBJECTS) -o $@

build/%.o: %.c
	@mkdir -p $(dir $@)
	$(info CC $<)
	@$(DOCKER) arm-none-eabi-gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf build/ firmware.axf firmware.bin
