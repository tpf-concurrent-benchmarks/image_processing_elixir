_common_folders:
	mkdir -p img
	mkdir -p img/input
	rm -rf img/formatted || true
	mkdir -p img/formatted
	rm -rf img/scaled || true
	mkdir -p img/scaled
	rm -rf img/output || true
	mkdir -p img/output
.PHONY: _common_folders

_run: _common_folders
	make run

run:
	mix compile
	mix run -e "ImageTransformations.main()"
