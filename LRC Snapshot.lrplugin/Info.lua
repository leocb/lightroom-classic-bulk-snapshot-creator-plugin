--[[
	LRC Snapshot
	Creates a Develop snapshot for every selected photo in one step.
]]

return {
	LrSdkVersion = 10.0,
	LrSdkMinimumVersion = 4.0,
	LrToolkitIdentifier = "com.leocb.lrcsnapshot",
	LrPluginName = "LRC Snapshot",
	LrPluginInfoUrl = "https://github.com/leocb/lightroom-classic-bulk-snapshot-creator-plugin",

	VERSION = {
		major = 1,
		minor = 0,
		revision = 1,
	},

	-- File > Plug-in Extras
	LrExportMenuItems = {
		title = "Create Snapshots for Selected Photos...",
		file = "CreateSnapshots.lua",
	},

	-- Library > Plug-in Extras
	LrLibraryMenuItems = {
		{
			title = "Create Snapshots for Selected Photos...",
			file = "CreateSnapshots.lua",
		},
	},
}
