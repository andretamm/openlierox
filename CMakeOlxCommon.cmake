# CMake common file for OpenLieroX
# sets up the source lists and vars

cmake_minimum_required(VERSION 2.4)
IF (${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION} GREATER 2.4)
	if(COMMAND CMAKE_POLICY)
		cmake_policy(VERSION 2.4)
		cmake_policy(SET CMP0005 OLD)
		cmake_policy(SET CMP0003 OLD)
		# Policy CMP0011 was introduced in 2.6.3.
		# We cannot do if(POLCY CMP0011) as a check because 2.4 would fail then.
		if(${CMAKE_MAJOR_VERSION} GREATER 2 OR ${CMAKE_MINOR_VERSION} GREATER 6 OR ${CMAKE_PATCH_VERSION} GREATER 2)
			# We explicitly want to export variables here.
			cmake_policy(SET CMP0011 OLD)
		endif(${CMAKE_MAJOR_VERSION} GREATER 2 OR ${CMAKE_MINOR_VERSION} GREATER 6 OR ${CMAKE_PATCH_VERSION} GREATER 2)
	endif(COMMAND CMAKE_POLICY)
	include(${OLXROOTDIR}/PCHSupport_26.cmake)
ENDIF (${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION} GREATER 2.4)


SET(SYSTEM_DATA_DIR "/usr/share/games" CACHE STRING "system data dir")
OPTION(DEBUG "enable debug build" Yes)
OPTION(DEDICATED_ONLY "dedicated_only - without gfx and sound" No)
OPTION(G15 "G15 support" No)
OPTION(X11 "X11 clipboard / notify" Yes)
OPTION(HAWKNL_BUILTIN "HawkNL builtin support" Yes)
OPTION(LIBZIP_BUILTIN "LibZIP builtin support" No)
OPTION(LIBLUA_BUILTIN "LibLua builtin support" Yes)
OPTION(STLPORT "STLport support" No)
OPTION(GCOREDUMPER "Google Coredumper support" No)
OPTION(PCH "Precompiled header (CMake 2.6 only)" No)
OPTION(ADVASSERT "Advanced assert" No)
OPTION(PYTHON_DED_EMBEDDED "Python embedded in dedicated server"  No)
OPTION(OPTIM_PROJECTILES "Enable optimisations for projectiles" Yes)
OPTION(MEMSTATS "Enable memory statistics and debugging" No)
OPTION(BREAKPAD "Google Breakpad support" Yes)
OPTION(DISABLE_JOYSTICK "Disable joystick support" No)
OPTION(MINGW_CROSS_COMPILE "Cross-compile Windows .EXE using i586-mingw32msvc-cc compiler" No)

IF (DEBUG)
	SET(CMAKE_BUILD_TYPE Debug)
ELSE (DEBUG)
	SET(CMAKE_BUILD_TYPE Release)
ENDIF (DEBUG)

IF (DEDICATED_ONLY)
	SET(X11 No)
	SET(WITH_G15 No)
ENDIF (DEDICATED_ONLY)

# Platform specific things can be put here
# Compilers and other specific variables can be found here:
# http://www.cmake.org/Wiki/CMake_Useful_Variables
IF(UNIX)
	IF(APPLE)
	ELSE(APPLE)
	ENDIF(APPLE)

	IF (CYGWIN)
		SET(WITH_G15 OFF) # Linux library as of now
	ELSE (CYGWIN)
	ENDIF (CYGWIN)
	IF(CMAKE_C_COMPILER MATCHES i586-mingw32msvc-cc)
		SET(MINGW_CROSS_COMPILE ON)
	ENDIF(CMAKE_C_COMPILER MATCHES i586-mingw32msvc-cc)
	IF (MINGW_CROSS_COMPILE)
		SET(G15 OFF)
		SET(HAWKNL_BUILTIN ON) # We already have prebuilt HawkNL library
		SET(LIBZIP_BUILTIN ON)
		SET(LIBLUA_BUILTIN ON)
		SET(X11 OFF)
		#SET(OPTIM_PROJECTILES OFF) # Inline optimized _powf and _powf defined in stdlib conflict at link time
		#SET(CMAKE_C_COMPILER i586-mingw32msvc-cc) # Does not work anyway, use mingw_cross_compile.sh script
		#SET(CMAKE_CXX_COMPILER i586-mingw32msvc-c++)
		#SET(CMAKE_C_FLAGS -Ibuild/mingw/include -Lbuild/mingw/lib)
		#SET(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})
	ENDIF (MINGW_CROSS_COMPILE)
ELSE(UNIX)
	IF(WIN32)
		SET(G15 OFF)
		SET(HAWKNL_BUILTIN OFF) # We already have prebuilt HawkNL library
		SET(X11 OFF)
	ELSE(WIN32)
	ENDIF(WIN32)
ENDIF(UNIX)


MESSAGE( "SYSTEM_DATA_DIR = ${SYSTEM_DATA_DIR}" )
MESSAGE( "DEBUG = ${DEBUG}" )
MESSAGE( "DEDICATED_ONLY = ${DEDICATED_ONLY}" )
MESSAGE( "G15 = ${G15}" )
MESSAGE( "X11 = ${X11}" )
MESSAGE( "HAWKNL_BUILTIN = ${HAWKNL_BUILTIN}" )
MESSAGE( "LIBZIP_BUILTIN = ${LIBZIP_BUILTIN}" )
MESSAGE( "LIBLUA_BUILTIN = ${LIBLUA_BUILTIN}" )
MESSAGE( "STLPORT = ${STLPORT}" )
MESSAGE( "GCOREDUMPER = ${GCOREDUMPER}" )
MESSAGE( "BREAKPAD = ${BREAKPAD}" )
MESSAGE( "CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}" )
MESSAGE( "CMAKE_C_FLAGS = ${CMAKE_C_FLAGS}" )
MESSAGE( "CMAKE_CXX_COMPILER = ${CMAKE_CXX_COMPILER}" )
MESSAGE( "CMAKE_CXX_FLAGS = ${CMAKE_CXX_FLAGS}" )
# commented out because only devs need these options anyway
#MESSAGE( "PCH = ${PCH} (Precompiled header, CMake 2.6 only)" )
#MESSAGE( "ADVASSERT = ${ADVASSERT}" )
#MESSAGE( "PYTHON_DED_EMBEDDED = ${PYTHON_DED_EMBEDDED}" )
MESSAGE( "MINGW_CROSS_COMPILE = ${MINGW_CROSS_COMPILE}" )


PROJECT(openlierox)

EXEC_PROGRAM(mkdir ARGS -p bin OUTPUT_VARIABLE DUMMY)

# main includes
INCLUDE_DIRECTORIES(${OLXROOTDIR}/optional-includes/generated)
INCLUDE_DIRECTORIES(${OLXROOTDIR}/include)
INCLUDE_DIRECTORIES(${OLXROOTDIR}/src)
INCLUDE_DIRECTORIES(${OLXROOTDIR}/libs/pstreams)

IF(ADVASSERT)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/optional-includes/advanced-assert)
ENDIF(ADVASSERT)

# TODO: don't hardcode path here
IF(NOT WIN32 AND NOT MINGW_CROSS_COMPILE)
	INCLUDE_DIRECTORIES(/usr/include/libxml2)
	INCLUDE_DIRECTORIES(/usr/local/include/libxml2)
ENDIF(NOT WIN32 AND NOT MINGW_CROSS_COMPILE)


file(GLOB_RECURSE GUS_SRCS ${OLXROOTDIR}/src/gusanos/*.c*)
file(GLOB_RECURSE GAME_SRCS ${OLXROOTDIR}/src/game/*.cpp)
file(GLOB_RECURSE SOUND_SRCS ${OLXROOTDIR}/src/sound/*.cpp)
file(GLOB_RECURSE UTIL_SRCS ${OLXROOTDIR}/src/util/*.cpp)
file(GLOB_RECURSE CLIENT_SRCS ${OLXROOTDIR}/src/client/*.cpp)
file(GLOB_RECURSE SERVER_SRCS ${OLXROOTDIR}/src/server/*.cpp)
file(GLOB_RECURSE COMMON_SRCS ${OLXROOTDIR}/src/common/*.cpp)

SET(ALL_SRCS ${GUS_SRCS} ${GAME_SRCS} ${SOUND_SRCS} ${UTIL_SRCS} ${CLIENT_SRCS} ${SERVER_SRCS} ${COMMON_SRCS})

IF(APPLE)
	SET(ALL_SRCS ${OLXROOTDIR}/src/MacMain.m ${ALL_SRCS})
ENDIF(APPLE)

SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/ExtractInfo.cpp ${ALL_SRCS})
IF (BREAKPAD)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/src/breakpad/external/src)
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/DumpSyms.cpp ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/BreakPad.cpp ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/on_demand_symbol_supplier.cpp ${ALL_SRCS})

	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/client/minidump_file_writer.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/client/linux/handler/exception_handler.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/client/linux/handler/linux_thread.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/client/linux/minidump_writer/linux_dumper.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/client/linux/minidump_writer/minidump_writer.cc ${ALL_SRCS})

	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/convert_UTF.c ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/md5.c ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/string_conversion.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/linux/file_id.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/linux/guid_creator.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/linux/dump_symbols.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/linux/module.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/linux/stabs_reader.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/dwarf/bytereader.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/dwarf/dwarf2diehandler.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/dwarf/dwarf2reader.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/common/linux/dump_dwarf.cc ${ALL_SRCS})

	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/basic_code_modules.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/basic_source_line_resolver.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/call_stack.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/logging.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/minidump.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/minidump_processor.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/pathname_stripper.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/process_state.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/simple_symbol_supplier.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/stackwalker_amd64.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/stackwalker_ppc.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/stackwalker_sparc.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/stackwalker_x86.cc ${ALL_SRCS})
	SET(ALL_SRCS ${OLXROOTDIR}/src/breakpad/external/src/processor/stackwalker.cc ${ALL_SRCS})
ELSE (BREAKPAD)
	ADD_DEFINITIONS(-DNBREAKPAD)
ENDIF (BREAKPAD)

IF (DISABLE_JOYSTICK)
	ADD_DEFINITIONS(-DDISABLE_JOYSTICK)
ENDIF (DISABLE_JOYSTICK)

IF (GCOREDUMPER)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/libs/coredumper/src)
	ADD_DEFINITIONS(-DGCOREDUMPER)
	AUX_SOURCE_DIRECTORY(${OLXROOTDIR}/libs/coredumper/src COREDUMPER_SRCS)
	SET(ALL_SRCS ${ALL_SRCS} ${COREDUMPER_SRCS})
ENDIF (GCOREDUMPER)

IF (HAWKNL_BUILTIN)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/libs/hawknl/include)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/crc.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/errorstr.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/nl.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/sock.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/group.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/loopback.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/err.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/thread.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/mutex.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/condition.c)
	SET(ALL_SRCS ${ALL_SRCS} ${OLXROOTDIR}/libs/hawknl/src/nltime.c)
ELSE (HAWKNL_BUILTIN)
	INCLUDE_DIRECTORIES(/usr/include/hawknl)
ENDIF (HAWKNL_BUILTIN)

IF (LIBZIP_BUILTIN)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/libs/libzip)
	AUX_SOURCE_DIRECTORY(${OLXROOTDIR}/libs/libzip LIBZIP_SRCS)
	SET(ALL_SRCS ${ALL_SRCS} ${LIBZIP_SRCS})
ENDIF (LIBZIP_BUILTIN)

IF (LIBLUA_BUILTIN)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/libs/lua)
	AUX_SOURCE_DIRECTORY(${OLXROOTDIR}/libs/lua LIBLUA_SRCS)
	SET(ALL_SRCS ${ALL_SRCS} ${LIBLUA_SRCS})
ELSE (LIBLUA_BUILTIN)
	INCLUDE_DIRECTORIES(/usr/include/lua5.1)
ENDIF (LIBLUA_BUILTIN)

IF (STLPORT)
	INCLUDE_DIRECTORIES(/usr/include/stlport)
	ADD_DEFINITIONS(-D_FILE_OFFSET_BITS=64) # hm, don't know, at least it works for me (ppc32/amd32)
# debugging stuff for STLport
	ADD_DEFINITIONS(-D_STLP_DEBUG=1)
	ADD_DEFINITIONS(-D_STLP_DEBUG_LEVEL=_STLP_STANDARD_DBG_LEVEL)
	ADD_DEFINITIONS(-D_STLP_SHRED_BYTE=0xA3)
	ADD_DEFINITIONS(-D_STLP_DEBUG_UNINITIALIZED=1)
	ADD_DEFINITIONS(-D_STLP_DEBUG_ALLOC=1)
ENDIF (STLPORT)


IF(DEBUG)
	ADD_DEFINITIONS(-DDEBUG=1 -D_AI_DEBUG)
ENDIF(DEBUG)

IF(MEMSTATS)
	ADD_DEFINITIONS(-include ${OLXROOTDIR}/optional-includes/memdebug/memstats.h)
ENDIF(MEMSTATS)


# Generic defines
IF(WIN32)
	ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE -DHAVE_BOOST -DZLIB_WIN32_NODLL)
	SET(OPTIMIZE_COMPILER_FLAG /Ox /Ob2 /Oi /Ot /GL)
	IF(DEBUG)
		ADD_DEFINITIONS(-DUSE_DEFAULT_MSC_DELEAKER)
	ELSE(DEBUG)
		ADD_DEFINITIONS(${OPTIMIZE_COMPILER_FLAG})
	ENDIF(DEBUG)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/libs/hawknl/include
				${OLXROOTDIR}/libs/hawknl/src
				${OLXROOTDIR}/libs/libzip
				${OLXROOTDIR}/libs/boost_process)
ELSE(WIN32)
	ADD_DEFINITIONS(-Wall)

	EXEC_PROGRAM(sh ARGS ${CMAKE_CURRENT_SOURCE_DIR}/get_version.sh OUTPUT_VARIABLE OLXVER)
	string(REGEX REPLACE "[\r\n]" " " OLXVER "${OLXVER}")
	MESSAGE( "OLX_VERSION = ${OLXVER}" )

	IF(MINGW_CROSS_COMPILE)
		ADD_DEFINITIONS(-DHAVE_BOOST -DZLIB_WIN32_NODLL -DLIBXML_STATIC -DNONDLL -DCURL_STATICLIB -D_XBOX # _XBOX to link OpenAL statically
							-D_WIN32_WINNT=0x0500 -D_WIN32_WINDOWS=0x0500 -DWINVER=0x0500)
		INCLUDE_DIRECTORIES(
					${OLXROOTDIR}/build/mingw/include
					${OLXROOTDIR}/libs/hawknl/include
					${OLXROOTDIR}/libs/hawknl/src
					${OLXROOTDIR}/libs/libzip
					${OLXROOTDIR}/libs/lua
					${OLXROOTDIR}/libs/boost_process)
		ADD_DEFINITIONS(-g2) # limit debug info somewhat, or it will produce huge .EXE
	ELSE(MINGW_CROSS_COMPILE)
		ADD_DEFINITIONS("-pthread")
	ENDIF(MINGW_CROSS_COMPILE)

	SET(OPTIMIZE_COMPILER_FLAG -O3)
ENDIF(WIN32)

IF(OPTIM_PROJECTILES)
	#Always optimize these files - they make debug build unusable otherwise
	SET_SOURCE_FILES_PROPERTIES(	${OLXROOTDIR}/src/common/PhysicsLX56_Projectiles.cpp 
						PROPERTIES COMPILE_FLAGS ${OPTIMIZE_COMPILER_FLAG})
ENDIF(OPTIM_PROJECTILES)

# SDL libs
IF(WIN32)
ELSEIF(APPLE)
	INCLUDE_DIRECTORIES(/Library/Frameworks/SDL.framework/Headers)
	INCLUDE_DIRECTORIES(/Library/Frameworks/SDL_image.framework/Headers)
	INCLUDE_DIRECTORIES(/Library/Frameworks/SDL_mixer.framework/Headers)
	INCLUDE_DIRECTORIES(/Library/Frameworks/UnixImageIO.framework/Headers)
	INCLUDE_DIRECTORIES(/Library/Frameworks/GD.framework/Headers)
ELSEIF(MINGW_CROSS_COMPILE)
	INCLUDE_DIRECTORIES(${OLXROOTDIR}/build/mingw/include/SDL)
ELSE()
	EXEC_PROGRAM(sdl-config ARGS --cflags OUTPUT_VARIABLE SDLCFLAGS)
	string(REGEX REPLACE "[\r\n]" " " SDLCFLAGS "${SDLCFLAGS}")
	ADD_DEFINITIONS(${SDLCFLAGS})
endif(WIN32)


IF(X11)
	ADD_DEFINITIONS("-DX11")
ENDIF(X11)
IF(DEDICATED_ONLY)
	ADD_DEFINITIONS("-DDEDICATED_ONLY")
ENDIF(DEDICATED_ONLY)


IF(G15)
	ADD_DEFINITIONS("-DWITH_G15")
ENDIF(G15)

SET(BOOST_LIB_SUFFIX)
IF(NOT MINGW_CROSS_COMPILE)
	EXEC_PROGRAM(cat ARGS /etc/debian_version OUTPUT_VARIABLE DEBIAN_VERSION)
	IF(DEBIAN_VERSION)
		SET(BOOST_LIB_SUFFIX "-mt")
	ENDIF(DEBIAN_VERSION)
ENDIF(NOT MINGW_CROSS_COMPILE)

SET(LIBS ${LIBS} curl boost_filesystem${BOOST_LIB_SUFFIX} boost_signals${BOOST_LIB_SUFFIX} alut openal vorbisfile)

if(APPLE)
	FIND_PACKAGE(SDL REQUIRED)
	FIND_PACKAGE(SDL_image REQUIRED)
	SET(LIBS ${LIBS} ${SDL_LIBRARY} ${SDLIMAGE_LIBRARY})
	SET(LIBS ${LIBS} "-framework Cocoa" "-framework Carbon")
else(APPLE)
	SET(LIBS ${LIBS} SDL SDL_image)
endif(APPLE)

IF(WIN32)
	SET(LIBS ${LIBS} SDL_mixer wsock32 wininet dbghelp
				"${OLXROOTDIR}/build/msvc/libs/SDLmain.lib"
				"${OLXROOTDIR}/build/msvc/libs/libxml2.lib"
				"${OLXROOTDIR}/build/msvc/libs/NLstatic.lib"
				"${OLXROOTDIR}/build/msvc/libs/libzip.lib"
				"${OLXROOTDIR}/build/msvc/libs/zlib.lib"
				"${OLXROOTDIR}/build/msvc/libs/bgd.lib")
ELSEIF(APPLE)
	link_directories(/Library/Frameworks/SDL_mixer.framework)
	link_directories(/Library/Frameworks/SDL_image.framework)
	link_directories(/Library/Frameworks/UnixImageIO.framework)
ELSEIF(MINGW_CROSS_COMPILE)

ELSE()
	EXEC_PROGRAM(sdl-config ARGS --libs OUTPUT_VARIABLE SDLLIBS)
	STRING(REGEX REPLACE "[\r\n]" " " SDLLIBS "${SDLLIBS}")
ENDIF(WIN32)

if(UNIX)
	IF (NOT HAWKNL_BUILTIN)
		SET(LIBS ${LIBS} NL)
	ENDIF (NOT HAWKNL_BUILTIN)
	IF (NOT LIBZIP_BUILTIN)
		SET(LIBS ${LIBS} zip)
	ENDIF (NOT LIBZIP_BUILTIN)
	IF (NOT LIBLUA_BUILTIN)
		SET(LIBS ${LIBS} lua5.1)
	ENDIF (NOT LIBLUA_BUILTIN)
	IF(X11)
		SET(LIBS ${LIBS} X11)
	ENDIF(X11)
	IF (STLPORT)
		SET(LIBS ${LIBS} stlportstlg)
	ENDIF (STLPORT)
	IF (G15)
		SET(LIBS ${LIBS} g15daemon_client g15render)
	ENDIF (G15)

	SET(LIBS ${LIBS} ${SDLLIBS} xml2 z)
	IF(NOT MINGW_CROSS_COMPILE)
		SET(LIBS ${LIBS} ${SDLLIBS} pthread)
	ENDIF(NOT MINGW_CROSS_COMPILE)
endif(UNIX)

IF (NOT DEDICATED_ONLY)
	if(APPLE)
		FIND_PACKAGE(SDL_mixer REQUIRED)
		SET(LIBS ${LIBS} ${SDLMIXER_LIBRARY})
		SET(LIBS ${LIBS} "-framework UnixImageIO" "-framework GD")
	elseif(UNIX)
		SET(LIBS ${LIBS} SDL_mixer gd)
	endif(APPLE)
ENDIF (NOT DEDICATED_ONLY)

IF(MINGW_CROSS_COMPILE)
	SET(LIBS ${LIBS} SDLmain boost_system jpeg png vorbisenc vorbis ogg dbghelp dsound dxguid wsock32 wininet wldap32 user32 gdi32 winmm version kernel32)
ENDIF(MINGW_CROSS_COMPILE)

ADD_DEFINITIONS('-D SYSTEM_DATA_DIR=\"${SYSTEM_DATA_DIR}\"')
