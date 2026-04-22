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

install: build
	cp -r $(APP) /Applications/
	osascript -e 'tell application "System Events" to make new login item at end with properties {path:"/Applications/SideNook.app", hidden:true}'
	@echo "SideNook installed and set to launch at login."

uninstall:
	osascript -e 'tell application "System Events" to delete login item "SideNook"' 2>/dev/null || true
	rm -rf /Applications/SideNook.app
