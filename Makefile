.PHONY: build run clean

BINARY_DIR = .build/release
BINARY     = $(BINARY_DIR)/SideNook
APP        = SideNook.app

build:
	swift build -c release
	mkdir -p $(APP)/Contents/MacOS
	mkdir -p $(APP)/Contents/Resources
	cp $(BINARY) $(APP)/Contents/MacOS/SideNook
	cp Resources/Info.plist $(APP)/Contents/

run: build
	open $(APP)

clean:
	rm -rf .build $(APP)
