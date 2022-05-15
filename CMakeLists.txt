cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

project(graphqlapi NONE)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})
set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY TRUE)

# Find Tarantool and Lua dependencies
set(TARANTOOL_FIND_REQUIRED ON)
find_package(Tarantool)
include_directories(${TARANTOOL_INCLUDE_DIRS})

file(GLOB_RECURSE LUA_FILES
  "${CMAKE_CURRENT_SOURCE_DIR}/graphqlapi.lua"
  "${CMAKE_CURRENT_SOURCE_DIR}/graphqlapi/*.lua"
  "${CMAKE_CURRENT_SOURCE_DIR}/graphqlapi/graphql/*.lua"
  "${CMAKE_CURRENT_SOURCE_DIR}/graphqlapi/helpers/*.lua"
  "${CMAKE_CURRENT_SOURCE_DIR}/cartridge/roles/*.lua"
)

file(GLOB_RECURSE LUA_DOCS
  "${CMAKE_CURRENT_SOURCE_DIR}/docs/*.md"
)

## VERSION ####################################################################
###############################################################################

execute_process(
  COMMAND git describe --tags --always
  WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  OUTPUT_STRIP_TRAILING_WHITESPACE
  OUTPUT_VARIABLE GIT_DESCRIBE
  ERROR_QUIET
)

if (NOT GIT_DESCRIBE)
  set(GIT_DESCRIBE "unknown")
endif()

configure_file (
  "${PROJECT_SOURCE_DIR}/graphqlapi/VERSION.lua.in"
  "${CMAKE_CURRENT_BINARY_DIR}/graphqlapi/VERSION.lua"
)

## Custom targets #############################################################
###############################################################################

add_custom_target(lint
  COMMAND .rocks/bin/luacheck .
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(test
  COMMAND .rocks/bin/luacheck .
  COMMAND rm -f tmp/luacov*
  COMMAND .rocks/bin/luatest --verbose --coverage --shuffle group
  COMMAND .rocks/bin/luacov . && grep -A999 '^Summary' tmp/luacov.report.out
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(build
  COMMAND tarantoolctl rocks make
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(pack
  COMMAND tarantoolctl rocks pack graphqlapi scm-1
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(deps
  COMMAND tarantoolctl rocks install cartridge 2.7.4
  COMMAND tarantoolctl rocks install luatest 0.5.7
  COMMAND tarantoolctl rocks install luacov 0.13.0
  COMMAND tarantoolctl rocks install luacheck 0.26.0
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(clean-all
  COMMAND rm -f CMakeCache.txt cmake_install.cmake Makefile
  COMMAND rm -rf build.luarocks/ CMakeFiles/
  COMMAND rm -rf .rocks
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(release
  COMMAND tarantoolctl rocks new_version --tag $(TAG)
  COMMAND tarantoolctl rocks make graphqlapi-$(TAG)-1.rockspec
  COMMAND tarantoolctl rocks pack graphqlapi
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(install-rock
  COMMAND tarantoolctl rocks install graphqlapi-scm-1.all.rock
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

## Install ####################################################################
###############################################################################

install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}
  PATTERN "*.in" EXCLUDE
)

install(
  FILES ${CMAKE_CURRENT_SOURCE_DIR}/graphqlapi.lua
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}
)

install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/cartridge
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}
)

install(
  FILES ${LUA_DOCS}
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}/../doc
)

install(
  FILES ${CMAKE_CURRENT_SOURCE_DIR}/README.md
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}/../doc
)

install(
  FILES ${CMAKE_CURRENT_SOURCE_DIR}/CHANGELOG.md
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}/../doc
)
