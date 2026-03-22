# Set OpenGL_GL_PREFERENCE to new "GLVND" even when legacy library exists and
# cmake is <= 3.10
#
# See https://cmake.org/cmake/help/latest/policy/CMP0072.html for more
# information.
if(POLICY CMP0072)
  cmake_policy(SET CMP0072 NEW)
endif()

# set(GRAPHIC_LIBRARIES "bgfx::bgfx bgfx::bx")
# TODO: Temporarily disable raylib graphic before bgfx is added.
set(GRAPHIC_LIBRARIES "")

if (${PLATFORM} MATCHES "Desktop")
    set(PLATFORM_CPP "PLATFORM_DESKTOP")

    if (APPLE)
        set(GRAPHICS "GRAPHICS_API_BGFX")
        link_libraries(${GRAPHIC_LIBRARIES})
    elseif (WIN32)
        add_definitions(-D_CRT_SECURE_NO_WARNINGS)
        set(GRAPHICS "GRAPHICS_API_BGFX")
        set(LIBS_PRIVATE ${GRAPHIC_LIBRARIES} winmm)
    elseif (UNIX)
        find_library(pthread NAMES pthread)

        if ("${CMAKE_SYSTEM_NAME}" MATCHES "(Net|Open)BSD")
            find_library(OSS_LIBRARY ossaudio)
        endif ()

        set(LIBS_PRIVATE m pthread ${GRAPHIC_LIBRARIES} ${OSS_LIBRARY})
    else ()
        find_library(pthread NAMES pthread)

        set(LIBS_PRIVATE m atomic pthread ${GRAPHIC_LIBRARIES} ${OSS_LIBRARY})

        if ("${CMAKE_SYSTEM_NAME}" MATCHES "(Net|Open)BSD")
            find_library(OSS_LIBRARY ossaudio)
            set(LIBS_PRIVATE m pthread ${GRAPHIC_LIBRARIES} ${OSS_LIBRARY})
        endif ()

        if (NOT "${CMAKE_SYSTEM_NAME}" MATCHES "(Net|Open)BSD" AND USE_AUDIO)
            set(LIBS_PRIVATE ${LIBS_PRIVATE} dl)
        endif ()
    endif ()

elseif (${PLATFORM} MATCHES "Web")
    set(PLATFORM_CPP "PLATFORM_WEB")
    set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")

elseif (${PLATFORM} MATCHES "Android")
    set(PLATFORM_CPP "PLATFORM_ANDROID")
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    list(APPEND raylib_sources ${ANDROID_NDK}/sources/android/native_app_glue/android_native_app_glue.c)
    include_directories(${ANDROID_NDK}/sources/android/native_app_glue)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--exclude-libs,libatomic.a -Wl,--build-id -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings -u ANativeActivity_onCreate -Wl,-undefined,dynamic_lookup")

    set(LIBS_PRIVATE m log android ${GRAPHIC_LIBRARIES} atomic c)

elseif ("${PLATFORM}" MATCHES "DRM")
    set(PLATFORM_CPP "PLATFORM_DRM")

    add_definitions(-D_DEFAULT_SOURCE)
    add_definitions(-DPLATFORM_DRM)

    find_library(DRM drm)
    find_library(GBM gbm)

    if (NOT CMAKE_CROSSCOMPILING OR NOT CMAKE_SYSROOT)
        include_directories(/usr/include/libdrm)
    endif ()
    set(LIBS_PRIVATE ${DRM} ${GBM} atomic pthread m dl)

elseif ("${PLATFORM}" MATCHES "SDL")
    find_package(SDL2 REQUIRED)
    set(PLATFORM_CPP "PLATFORM_DESKTOP_SDL")
    set(LIBS_PRIVATE SDL2::SDL2)

endif ()

if (NOT GRAPHICS)
    set(GRAPHICS "GRAPHICS_API_BGFX")
endif ()

set(LIBS_PRIVATE ${LIBS_PRIVATE} ${GRAPHIC_LIBRARIES})

if (${PLATFORM} MATCHES "Desktop")
    set(LIBS_PRIVATE ${LIBS_PRIVATE} glfw)
endif ()
