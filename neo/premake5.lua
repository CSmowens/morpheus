-- morpheus premake5 build script
morpheus =
{
	-- The engine executables will be output here
	outputPath = nil,

	-- If outputPath is set, the game dlls will be output to this subdirectory of outputPath
	outputBase = nil,
}

-- Include the custom configuration file if it exists
local customFilename = "premake5-custom.lua"

if os.isfile(customFilename) then
	dofile(customFilename)
end

-- Include DX SDK location for MSVC
local DXSDK = os.getenv("DXSDK_DIR")
local DXSDK_INCLUDE = DXSDK .. "/Include"
local DXSDK_LIB = DXSDK .. "/Lib/x86"

-----------------------------------------------------------------------------

solution "morpheus"
	location "msvc-premake"
	startproject "doom"
	
	platforms { "native", "universal", "x32", "x64", "ppc" }
	configurations { "Debug", "Release" }
	flags { "FloatFast" }
	
	-- various platform-specific build flags
    if os.is( "windows" ) then
        defines { "_CRT_SECURE_NO_DEPRECATE", "_CRT_NONSTDC_NO_DEPRECATE", "WIN32", "_WIN32", "_AFXDLL" }
        flags { "No64BitChecks" }
    else
        -- *nix
        buildoptions {
            "-Wunused-parameter",
            "-Wredundant-decls",    -- (useful for finding some multiply-included header files)
            "-Wundef",              -- (useful for finding macro name typos)

            -- enable security features (stack checking etc) that shouldn't have
            -- a significant effect on performance and can catch bugs
            "-fstack-protector-all",

            -- always enable strict aliasing (useful in debug builds because of the warnings)
            "-fstrict-aliasing",

            -- do something (?) so that ccache can handle compilation with PCH enabled
            "-fpch-preprocess",

            -- enable SSE intrinsics
            "-msse",

            -- don't omit frame pointers (for now), because performance will be impacted
            -- negatively by the way this breaks profilers more than it will be impacted
            -- positively by the optimisation
            "-fno-omit-frame-pointer"
        }

        if os.is( "linux" ) then
            defines { "LINUX" }
            linkoptions { "-Wl,--no-undefined", "-Wl,--as-needed" }
        end

        -- To support intrinsics like __sync_bool_compare_and_swap on x86
        -- we need to set -march to something that supports them
        if arch == "x86" then
            buildoptions { "-march=i686" }
        end

        -- We don't want to require SSE2 everywhere yet, but OS X headers do
        -- require it (and Intel Macs always have it) so enable it here
        if os.is( "macosx" ) then
            defines { "MACOS_X" }
            buildoptions { "-msse2" }
        end
    end	
	
	configuration "Debug"
		optimize "Debug"
		defines "_DEBUG"
		flags { "Symbols" }
				
	configuration "Release"
		optimize "Full"
		defines "NDEBUG"
		flags { "OptimizeSpeed", "NoEditAndContinue" }
	
-----------------------------------------------------------------------------

project "idLib"
	kind "StaticLib"
	language "C++"

	configuration "x64"
		targetname "idLib_x86_64"
	configuration "not x64"
		targetname "idLib_x86"
	configuration {}
		pchheader "precompiled.h"
		pchsource "../neo/idlib/precompiled.cpp"

	files
	{
		"../neo/idlib/bv/*.cpp",
		"../neo/idlib/bv/*.h",
		"../neo/idlib/containers/*.cpp",
		"../neo/idlib/containers/*.h",
		"../neo/idlib/geometry/*.cpp",
		"../neo/idlib/geometry/*.h",
		"../neo/idlib/hashing/*.cpp",
		"../neo/idlib/hashing/*.h",
		"../neo/idlib/math/*.cpp",
		"../neo/idlib/math/*.h",
		"../neo/idlib/*.cpp",
		"../neo/idlib/*.h",
	}
	
	excludes
	{
		"../neo/idlib/bv/Frustum_gcc.cpp",
	}	
	
	includedirs
	{
		"../neo/idlib",
	}
	
	configuration "Debug"
		if morpheus.outputPath == nil then
			targetdir "../build/idLib_debug"
		else
			targetdir(morpheus.outputPath)
		end
		
		objdir "../build/idLib_debug"
				
	configuration "Release"
		if morpheus.outputPath == nil then
			targetdir "../build/idLib_release"
		else
			targetdir(morpheus.outputPath)
		end
		
		objdir "../build/idLib_release"
		
-----------------------------------------------------------------------------

project "curlLib"
	kind "StaticLib"
	language "C"

	configuration "x64"
		targetname "curlLib_x86_64"
	configuration "not x64"
		targetname "curlLib_x86"
	configuration {}

	files
	{
		"../neo/curl/lib/*.c",
		"../neo/curl/lib/*.h",
	}
	
	includedirs
	{
		"../neo/curl/include",
	}
	
	configuration "Debug"
		if morpheus.outputPath == nil then
			targetdir "../build/curlLib_debug"
		else
			targetdir(morpheus.outputPath)
		end
		
		objdir "../build/curlLib_debug"
				
	configuration "Release"
		if morpheus.outputPath == nil then
			targetdir "../build/curlLib_release"
		else
			targetdir(morpheus.outputPath)
		end
		
		objdir "../build/curlLib_release"		
		
-----------------------------------------------------------------------------
	
project "doom"
	kind "WindowedApp"
	language "C++"
	flags { "WinMain" }
	
	configuration "x64"
		targetname "doom.x86_64"
	configuration "not x64"
		targetname "doom.x86"
	configuration {}
	
	defines
	{
		"__DOOM_DLL__"
	}
	
	files
	{
		"../neo/renderer/jpeg-6/*.c",
		"../neo/renderer/jpeg-6/*.h",
		
		"../neo/sound/OggVorbis/ogg/*.h",
		"../neo/sound/OggVorbis/oggsrc/*.c",
		"../neo/sound/OggVorbis/oggsrc/*.h",
		
		"../neo/sound/OggVorbis/vorbis/*.h",
		"../neo/sound/OggVorbis/vorbissrc/*.c",
		"../neo/sound/OggVorbis/vorbissrc/*.h",		
		
		"../neo/cm/*.cpp",
		"../neo/cm/*.h",
		"../neo/framework/*.cpp",
		"../neo/framework/*.h",
		"../neo/framework/async/*.cpp",
		"../neo/framework/async/*.h",
		"../neo/renderer/*.cpp",
		"../neo/renderer/*.h",
		"../neo/sound/*.cpp",
		"../neo/sound/*.h",
		"../neo/sys/*.cpp",
		"../neo/sys/*.h",
		"../neo/tools/*.cpp",
		"../neo/tools/*.h",
		"../neo/tools/compilers/*.h",
		"../neo/tools/compilers/aas/*.cpp",
		"../neo/tools/compilers/aas/*.h",
		"../neo/tools/compilers/dmap/*.cpp",
		"../neo/tools/compilers/dmap/*.h",	
		"../neo/tools/compilers/renderbump/*.cpp",
		"../neo/tools/compilers/renderbump/*.h",	
		"../neo/tools/compilers/roqvq/*.cpp",
		"../neo/tools/compilers/roqvq/*.h",	
		"../neo/ui/*.cpp",
		"../neo/ui/*.h",
		"../neo/idlib/precompiled.cpp",
	}
	
	excludes
	{
		"../neo/openal/stubs.cpp",
		"../neo/openal/idal.cpp",
	}		
	
	includedirs
	{
		"../neo/renderer/jpeg-6",
		"../neo/openal/include",
		"../neo/curl/include",
		"../neo/idlib",
	}	
	
	-- Platform Specifics
	if os.is( "windows" ) then
		files
		{
			"../neo/sys/win32/*.cpp",
			"../neo/sys/win32/rc/doom.rc",
		}
		includedirs( DXSDK_INCLUDE )
		libdirs( DXSDK_LIB )
		excludes
		{
			"../neo/sys/win32/gl_logfuncs.cpp",
			"../neo/sys/win32/gl_logfuncs.cpp",
		}
		links
		{
			"user32",
			"advapi32",
			"winmm",
			"wsock32",
			"ws2_32",
			"iphlpapi",
			"Dbghelp",
			"OpenGL32",
			"psapi",
			"gdi32",
			"dxguid",
			"DxErr",
			"dsound",
			"dinput8",
			"../neo/openal/lib/openal32",
			"../neo/openal/lib/eaxguid",
			
			-- Other projects
			"curlLib",
			"idLib",
		}	
		linkoptions
		{
			"/SAFESEH:NO" -- for MSVC2012
		}
	elseif os.is( "linux" ) then
		links { "m", "dl", "pthread" }
	elseif os.is( "macosx" ) then
		links { "Foundation.framework", "AppKit.framework" }
	end

	configuration "Debug"
		if morpheus.outputPath == nil then
			targetdir "../build/doom_debug"
		else
			targetdir(morpheus.outputPath)
		end

		objdir "../build/doom_debug"
				
	configuration "Release"
		if morpheus.outputPath == nil then
			targetdir "../build/doom_release"
		else
			targetdir(morpheus.outputPath)
		end
		
		objdir "../build/doom_release"

-----------------------------------------------------------------------------

project "doom_game"
	kind "SharedLib"
	language "C++"

	configuration "x64"
		targetname "gamex86_64"
	configuration "not x64"
		targetname "gamex86"
	configuration {}
		
	defines
	{
		"GAME_DLL",
	}
	
	files
	{
		"../neo/game/ai/*.cpp",
		"../neo/game/ai/*.h",
		"../neo/game/anim/*.cpp",
		"../neo/game/anim/*.h",
		"../neo/game/gamesys/*.cpp",
		"../neo/game/gamesys/*.h",
		"../neo/game/physics/*.cpp",
		"../neo/game/physics/*.h",
		"../neo/game/script/*.cpp",
		"../neo/game/script/*.h",
		"../neo/game/*.cpp",
		"../neo/game/*.h",
		"../neo/idlib/precompiled.cpp",
	}
	
	excludes
	{
		"../neo/game/gamesys/Callbacks.cpp",
	}
	
	includedirs
	{
		"../neo/idlib",
	}	
	
	links
	{
		-- Other projects
		"idLib",
	}	

	configuration "Debug"
		if morpheus.outputPath == nil and morpheus.outputBase == nil then
			targetdir "../build/doom_game_debug"
		else
			targetdir(morpheus.outputPath .. "\\" .. morpheus.outputBase)
		end
		
		objdir "../build/doom_game_debug"
				
	configuration "Release"
		if morpheus.outputPath == nil and morpheus.outputBase == nil then
			targetdir "../build/doom_game_release"
		else
			targetdir(morpheus.outputPath .. "\\" .. morpheus.outputBase)
		end
		
		objdir "../build/doom_game_release"

-----------------------------------------------------------------------------
