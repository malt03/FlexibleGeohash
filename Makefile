PLATFORM = x86_64-apple-macosx
TEST_RESOURCES_DIRECTORY = ./.build/${PLATFORM}/debug/FlexibleGeohashPackageTests.xctest/Contents/Resources

copyTestResources:
	mkdir -p ${TEST_RESOURCES_DIRECTORY}
	cp ./Tests/Resources/* ${TEST_RESOURCES_DIRECTORY}

test: copyTestResources
	swift test
