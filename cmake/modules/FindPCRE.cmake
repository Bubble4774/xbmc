#.rst:
# FindPCRE
# --------
# Finds the PCRE library
#
# This will define the following targets:
#
#   ${APP_NAME_LC}::PCRE    - The PCRE library

macro(buildPCRE)
  set(PCRE_VERSION ${${MODULE}_VER})
  set(PCRE_DEBUG_POSTFIX d)

  set(patches "${CORE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/001-all-cmakeconfig.patch"
              "${CORE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/002-all-enable_docs_pc.patch"
              "${CORE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/003-all-postfix.patch"
              "${CORE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/004-win-pdb.patch"
              "${CORE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/jit_aarch64.patch")

  if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
    list(APPEND patches "${CORE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/tvos-bitcode-fix.patch"
                        "${CORE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/ios-clear_cache.patch")
  endif()

  generate_patchcommand("${patches}")

  set(CMAKE_ARGS -DPCRE_NEWLINE=ANYCRLF
                 -DPCRE_NO_RECURSE=ON
                 -DPCRE_MATCH_LIMIT_RECURSION=1500
                 -DPCRE_SUPPORT_JIT=ON
                 -DPCRE_SUPPORT_PCREGREP_JIT=ON
                 -DPCRE_SUPPORT_UTF=ON
                 -DPCRE_SUPPORT_UNICODE_PROPERTIES=ON
                 -DPCRE_SUPPORT_LIBZ=OFF
                 -DPCRE_SUPPORT_LIBBZ2=OFF
                 -DPCRE_BUILD_PCREGREP=OFF
                 -DPCRE_BUILD_TESTS=OFF)

  if(WIN32 OR WINDOWS_STORE)
    list(APPEND CMAKE_ARGS -DINSTALL_MSVC_PDB=ON)

    # PCRE fails due to C4703 and C4146 when /SDL is enabled
    set(PCRE_C_FLAGS "/sdl-")
    set(PCRE_CXX_FLAGS "/sdl-")
  elseif(CORE_SYSTEM_NAME STREQUAL android)
    # CMake CheckFunctionExists incorrectly detects strtoq for android
    list(APPEND CMAKE_ARGS -DHAVE_STRTOQ=0)
  endif()

  # populate PCRE lib without a separate module
  if(NOT CORE_SYSTEM_NAME MATCHES windows)
    # Non windows platforms have a lib prefix for the lib artifact
    set(_libprefix "lib")
  endif()

  BUILD_DEP_TARGET()
endmacro()

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC pcre)

  SETUP_BUILD_VARS()

  # Check for existing PCRE. If version >= PCRE-VERSION file version, dont build
  find_package(PCRE CONFIG QUIET
                           HINTS ${DEPENDS_PATH}/lib/cmake
                           ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  if((PCRE_VERSION VERSION_LESS ${${MODULE}_VER} AND ENABLE_INTERNAL_PCRE) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_PCRE))

    buildPCRE()

  else()
    if(NOT TARGET PCRE::pcre)
      find_package(PkgConfig)
      if(PKG_CONFIG_FOUND AND NOT (WIN32 OR WINDOWS_STORE))
        pkg_check_modules(PC_PCRE pcre QUIET)
      endif()

      find_path(PCRE_INCLUDE_DIR pcre.h
                                 HINTS ${DEPENDS_PATH}/include ${PC_PCRE_INCLUDEDIR}
                                 ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})
      find_library(PCRE_LIBRARY_RELEASE NAMES pcre
                                        HINTS ${DEPENDS_PATH}/lib ${PC_PCRE_LIBDIR}
                                        ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})
      find_library(PCRE_LIBRARY_DEBUG NAMES pcred
                                      HINTS ${DEPENDS_PATH}/lib ${PC_PCRE_LIBDIR}
                                      ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})
      set(PCRE_VERSION ${PC_PCRE_VERSION})
    else()
      # Populate variables for find_package_handle_standard_args usage
      get_target_property(_PCRE_CONFIGURATIONS PCRE::pcre IMPORTED_CONFIGURATIONS)
      foreach(_pcre_config IN LISTS _PCRE_CONFIGURATIONS)
        # Just set to RELEASE var so select_library_configurations can continue to work its magic
        if((NOT ${_pcre_config} STREQUAL "RELEASE") AND
           (NOT ${_pcre_config} STREQUAL "DEBUG"))
          get_target_property(PCRE_LIBRARY_RELEASE PCRE::pcre IMPORTED_LOCATION_${_pcre_config})
        else()
          get_target_property(PCRE_LIBRARY_${_pcre_config} PCRE::pcre IMPORTED_LOCATION_${_pcre_config})
        endif()
      endforeach()

      # ToDo: patch PCRE cmake to include includedir in config file
      find_path(PCRE_INCLUDE_DIR pcre.h
                                 HINTS ${DEPENDS_PATH}/include ${PC_PCRE_INCLUDEDIR}
                                 ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

      set_target_properties(PCRE::pcre PROPERTIES
                                       INTERFACE_INCLUDE_DIRECTORIES "${PCRE_INCLUDE_DIR}")
    endif()
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(PCRE)
  unset(PCRE_LIBRARIES)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(PCRE
                                    REQUIRED_VARS PCRE_LIBRARY PCRE_INCLUDE_DIR
                                    VERSION_VAR PCRE_VERSION)

  if(PCRE_FOUND)
    # cmake target and not building internal
    if(TARGET PCRE::pcre AND NOT TARGET pcre)
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS PCRE::pcre)
    else()
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} UNKNOWN IMPORTED)
      if(PCRE_LIBRARY_RELEASE)
        set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                         IMPORTED_CONFIGURATIONS RELEASE
                                                                         IMPORTED_LOCATION_RELEASE "${PCRE_LIBRARY_RELEASE}")
      endif()
      if(PCRE_LIBRARY_DEBUG)
        set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                         IMPORTED_LOCATION_DEBUG "${PCRE_LIBRARY_DEBUG}")
        set_property(TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} APPEND PROPERTY
                                                                              IMPORTED_CONFIGURATIONS DEBUG)
      endif()
      set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                       INTERFACE_INCLUDE_DIRECTORIES "${PCRE_INCLUDE_DIR}")
    endif()

    # Wee need to explicitly add this define. The cmake config does not propagate this info
    if(WIN32)
      get_target_property(aliased_target ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIASED_TARGET)

      if(NOT aliased_target OR "${aliased_target}" STREQUAL "")
        set(_pcre_target "${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME}")
      else()
        set(_pcre_target "${aliased_target}")
      endif()

      set_property(TARGET ${_pcre_target} APPEND PROPERTY
                                                 INTERFACE_COMPILE_DEFINITIONS "PCRE_STATIC")
    endif()

    if(TARGET pcre)
      add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} pcre)
    endif()

    # Add internal build target when a Multi Config Generator is used
    # We cant add a dependency based off a generator expression for targeted build types,
    # https://gitlab.kitware.com/cmake/cmake/-/issues/19467
    # therefore if the find heuristics only find the library, we add the internal build
    # target to the project to allow user to manually trigger for any build type they need
    # in case only a specific build type is actually available (eg Release found, Debug Required)
    # This is mainly targeted for windows who required different runtime libs for different
    # types, and they arent compatible
    if(_multiconfig_generator)
      if(NOT TARGET pcre)
        buildPCRE()
        set_target_properties(pcre PROPERTIES EXCLUDE_FROM_ALL TRUE)
      endif()
      add_dependencies(build_internal_depends pcre)
    endif()
  else()
    if(PCRE_FIND_REQUIRED)
      message(FATAL_ERROR "PCRE library not found. You may want to try -DENABLE_INTERNAL_PCRE=ON")
    endif()
  endif()
endif()
