# Nap them cac lop cau noi JS <-> iOS ma game goi toi
target_sources(${CC_EXECUTABLE_NAME} PRIVATE ${CC_PROJECT_DIR}/AppGame.mm)
set_source_files_properties(${CC_PROJECT_DIR}/AppGame.mm PROPERTIES COMPILE_FLAGS "-fobjc-arc")
