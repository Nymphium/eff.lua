-- vim: ft=lua

include_files = {"src", "spec/*.lua", "scripts/*.lua", "*.rockspec", "*.luacheckrc"}
std = "max"
stds.busted_patch = {
   read_globals = { "randomize" }
}

files["spec/*.lua"].std = "+busted+busted_patch"
ignore = {"432"}
