SHELL := /bin/bash

BUNDLE_VERSION=2.8.2-0-gfc96d10f5-r429

.PHONY: .rocks
.rocks: graphqlapi-scm-1.rockspec Makefile
		tarantoolctl rocks make
		tarantoolctl rocks install luatest 0.5.6
		tarantoolctl rocks install luacov 0.13.0
		tarantoolctl rocks install luacheck 0.26.0
		tarantoolctl rocks install cartridge 2.7.3
		tarantoolctl rocks make graphqlapi-scm-1.rockspec

.PHONY: lint
lint:
		@ if [ ! -d ".rocks" ]; then make .rocks; fi
		.rocks/bin/luacheck .

.PHONY: test
test: 	lint
		rm -f tmp/luacov*
		.rocks/bin/luatest --verbose --coverage --shuffle group
		.rocks/bin/luacov . && grep -A999 '^Summary' tmp/luacov.report.out

.PHONY: clean
clean:
		rm -rf .rocks

.PHONY: rock
rock:
		@ if [ ! -d ".rocks" ]; then make .rocks; fi
		tarantoolctl rocks make
		tarantoolctl rocks pack graphqlapi

.PHONY: install
install:
		tarantoolctl rocks install graphqlapi-scm-1.all.rock

.PHONY: sdk
sdk: 	Makefile
		wget https://tarantool:$(DOWNLOAD_TOKEN)@download.tarantool.io/enterprise/tarantool-enterprise-bundle-$(BUNDLE_VERSION).tar.gz
		tar -xzf tarantool-enterprise-bundle-$(BUNDLE_VERSION).tar.gz
		rm tarantool-enterprise-bundle-$(BUNDLE_VERSION).tar.gz
		mv tarantool-enterprise sdk

push-scm-1:
		curl --fail -X PUT -F "rockspec=@graphqlapi-scm-1.rockspec" https://${ROCKS_USERNAME}:${ROCKS_PASSWORD}@rocks.tarantool.org

push-release:
		cd release/ \
		&& curl --fail -X PUT -F "rockspec=@graphqlapi-${COMMIT_TAG}-1.rockspec" https://${ROCKS_USERNAME}:${ROCKS_PASSWORD}@rocks.tarantool.org \
		&& curl --fail -X PUT -F "rockspec=@graphqlapi-${COMMIT_TAG}-1.all.rock" https://${ROCKS_USERNAME}:${ROCKS_PASSWORD}@rocks.tarantool.org
