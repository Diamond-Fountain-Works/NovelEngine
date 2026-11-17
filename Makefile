.PHONY: build run test check qa
build:
	./script/build_and_run.sh --build
run:
	./script/build_and_run.sh
test:
	swift test --package-path packages/novel-core-swift --scratch-path build/core
	swift test --package-path packages/novel-ui-apple --scratch-path build/ui-tests
	swift test --package-path apps/apple/macOS --scratch-path build/native-tests
check:
	python3 scripts/check_project.py
	python3 scripts/check_publication.py
qa: build test check
