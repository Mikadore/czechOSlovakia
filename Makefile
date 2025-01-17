kernel := build/kernel.bin
iso := build/os.iso

linker_script := src/boot/linker.ld
grub_cfg := src/boot/grub.cfg
assembly_source_files := $(wildcard src/boot/*.asm)
assembly_object_files := $(patsubst src/boot/%.asm, \
	build/boot/%.o, $(assembly_source_files))

.PHONY: all clean run iso

all: $(kernel)

clean:
	@rm -r build

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso) -serial stdio

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): kernel target/x86_64_target/release/libos.a $(assembly_object_files) $(linker_script)
	@ld -n -T $(linker_script) -o $(kernel) \
		$(assembly_object_files) target/x86_64_target/release/libos.a


# compile assembly files
build/boot/%.o: src/boot/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@

kernel:
	cargo build --release