cmake_minimum_required(VERSION 2.8)
project(objc_msgSend_test)

find_package(WiiStep REQUIRED)

# Create targets and what-not down here
add_wii_executable(objc_msgSend objc_msgSend.m)
