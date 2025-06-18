list:
    @just --list

generate-demo-repo:
    ./scripts/generate-demo-repo.sh

build-xcode-16:
    env DEVELOPER_DIR="/Applications/Xcode-16.4.0.app/Contents/Developer" xcodebuild -project Judo.xcodeproj -scheme Judo -configuration Release -destination 'platform=macOS' build

build-xcode-26:
    env DEVELOPER_DIR="/Applications/Xcode-26.0.0-beta.app/Contents/Developer" xcodebuild -project Judo.xcodeproj -scheme Judo -configuration Release -destination 'platform=macOS' build
