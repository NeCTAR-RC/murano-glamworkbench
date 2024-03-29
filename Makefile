TARGET=au.org.nectar.GlamWorkbench
.PHONY: package.zip

all: package.zip

build: package.zip

clean:
	rm -rf package.zip

upload: package.zip
	murano package-import -c "Big Data" --package-version 1.0 --exists-action u package.zip

check: package.zip
	murano-pkg-check package.zip

public:
	@echo "Searching for $(TARGET) package ID..."
	@package_id=$$(murano package-list --fqn $(TARGET) | grep $(TARGET) | awk '{print $$2}'); \
	echo "Found ID: $$package_id"; \
	murano package-update --is-public true $$package_id

package.zip:
	rm -f $@; cd $(TARGET); zip ../$@ -r *; cd ..
