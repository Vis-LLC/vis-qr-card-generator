def getBuildPlatform():
	from sys import platform
	match platform:
		case "aix":
			return "unix"
		case "linux":
			return "unix"
		case "windows":
			return "windows"
		case "win32":
			return "windows"
		case "cygwin":
			return "unix"
		case "darwin":
			return "unix"

def getLanguageSwitch():
	import sys
	return sys.argv[1]

def getPlatformSwitch():
	import sys
	return "-D " + sys.argv[2]

buildPlatform = getBuildPlatform()
languageSwitch = getLanguageSwitch()
platformSwitch = getPlatformSwitch()

def buildPath(arr):
	global buildPlatform
	match buildPlatform:
		case "unix":
			return "/".join(arr)
		case "windows":
			return "\\".join(arr)

def mkdir(path):
	import os
	try:
		os.mkdir(buildPath(path))
	except:
		pass

def rm(path):
	import shutil
	try:
		shutil.rmtree(buildPath(path))
	except:
		pass
	import os
	try:
		os.remove(buildPath(path))
	except:
		pass
	try:
		os.unlink(buildPath(path))
	except:
		pass

def move(src, to):
	import os
	rm(to)
	os.rename(buildPath(src), buildPath(to))

def append(src, to, appending):
	with open(buildPath(to), "a" if appending else "w+") as fo:
		with open(buildPath(src), "r") as fi:
			fo.write(fi.read())
def run(program, parameters):
	import os
	print(" ".join([program] + parameters))
	os.system(" ".join([program] + parameters))

def haxe(out, src, package, defines):
	global languageSwitch
	global platformSwitch
	if defines == None:
		defines = [ ]
	for i in range(len(src)):
		src[i] = "-cp " + src[i]
	run("haxe", [languageSwitch, buildPath(["out", out])] + src + [ package, platformSwitch] + defines)

if languageSwitch != "CLEAN":
	out1 = "QRGenerator"
	if languageSwitch == "--python":
		out2 = ".py"
		appendFile = "Append_To_Beginning.py"
	elif languageSwitch == "-cs":
		out2 = ".dll"
		appendFile = None
	elif languageSwitch == "-hl":
		out2 = "-lib.hl"
		appendFile = None
	elif languageSwitch == "-java":
		out2 = ".jar"
		appendFile = None
	elif languageSwitch == "-lua":
		out2 = ".lua"
		appendFile = "Append_To_Beginning.lua"
	elif platformSwitch == "-D JS_BROWSER":
		out2 = "-browser.js"
		appendFile = "Append_To_Beginning.txt"
	elif platformSwitch == "-D JS_WSH":
		out2 = "-wsh.js"
		appendFile = "Append_To_Beginning.txt"	

	# TODO - Add Lua TI
	# TODO - Add PHP
	# TODO - Add Docs
	# TODO - Add UML

	out = out1 + out2

	print("Building Library")
	mkdir(["out"])
	rm(["out", "build.tmp"])
	rm(["out", out])
	haxe(out, ["src", "lib-src"], "com.vis.qrcardgenerator", [
			"--macro \"exclude('com.sdtk', true)\"", "--macro \"exclude('com.field', true)\""
	])
	if languageSwitch == "-java":
		move(["out", out, out + ".jar"], ["out", "build.tmp"])
		rm(["out", out])
	else:
		move(["out", out], ["out", "build.tmp"])
	if appendFile != None:
		append(["Append_To_Beginning.txt"], ["out", out], False)
	if appendFile == None:
		move(["out", "build.tmp"], ["out", out])
	else:
		append(["out", "build.tmp"], ["out", out], True)
	rm(["out", "build.tmp"])
else:
	rm(["out"])



