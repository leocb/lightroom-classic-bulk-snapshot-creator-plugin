--[[
	CreateSnapshots.lua
	Creates a Develop snapshot for each selected photo.
]]

local LrApplication = import "LrApplication"
local LrBinding = import "LrBinding"
local LrDate = import "LrDate"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local LrPathUtils = import "LrPathUtils"
local LrPrefs = import "LrPrefs"
local LrProgressScope = import "LrProgressScope"
local LrTasks = import "LrTasks"
local LrView = import "LrView"

local TokenExpander = require "TokenExpander"

local DEFAULT_TEMPLATE = "{filename} - {date}"
local PREF_TEMPLATE = "snapshotNameTemplate"
local PREF_UPDATE_EXISTING = "updateExistingSnapshot"

local RAW_METADATA_KEYS = {
	"path",
	"isVideo",
	"dateTimeOriginal",
	"aperture",
	"shutterSpeed",
	"isoSpeedRating",
	"focalLength",
	"rating",
	"colorNameForLabel",
	"fileFormat",
}

local FORMATTED_METADATA_KEYS = {
	"fileName",
	"folderName",
	"cameraMake",
	"cameraModel",
	"lens",
}

local function trim(value)
	value = value or ""
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function plural(count, singular, pluralForm)
	if count == 1 then
		return singular
	end
	return pluralForm or (singular .. "s")
end

local function photoLabel(data, index)
	if data.fileName and data.fileName ~= "" then
		return data.fileName
	end
	if data.path and data.path ~= "" then
		local name = LrPathUtils.leafName(data.path)
		if name and name ~= "" then
			return name
		end
	end
	return string.format("Photo %d", index)
end

local function buildPhotoData(catalog, photos)
	local rawMetadata = catalog:batchGetRawMetadata(photos, RAW_METADATA_KEYS) or {}
	local formattedMetadata = catalog:batchGetFormattedMetadata(photos, FORMATTED_METADATA_KEYS) or {}

	local result = {}
	for index, photo in ipairs(photos) do
		local raw = rawMetadata[photo] or {}
		local formatted = formattedMetadata[photo] or {}

		result[index] = {
			path = raw.path,
			fileName = formatted.fileName,
			folder = formatted.folderName,
			cameraMake = formatted.cameraMake,
			cameraModel = formatted.cameraModel,
			lens = formatted.lens,
			isVideo = raw.isVideo == true,
			captureTime = raw.dateTimeOriginal,
			iso = raw.isoSpeedRating,
			aperture = raw.aperture,
			shutter = raw.shutterSpeed,
			focalLength = raw.focalLength,
			rating = raw.rating,
			label = raw.colorNameForLabel,
			fileFormat = raw.fileFormat,
		}
	end
	return result
end

local function buildTokenHelpText()
	local lines = {}

	for _, group in ipairs(TokenExpander.tokenGroups) do
		if #lines > 0 then
			lines[#lines + 1] = ""
		end
		lines[#lines + 1] = group.title
		for _, item in ipairs(group.tokens) do
			lines[#lines + 1] = string.format("  %-20s %s", item.token, item.description)
		end
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "Use {{ and }} for literal braces. Unknown tokens are left unchanged."
	return table.concat(lines, "\n")
end

local function promptForOptions(photos, photoData, now)
	local prefs = LrPrefs.prefsForPlugin()
	local currentTemplate = prefs[PREF_TEMPLATE] or DEFAULT_TEMPLATE
	local currentUpdateExisting = prefs[PREF_UPDATE_EXISTING] == true
	local tokenHelpText = buildTokenHelpText()

	while true do
		local chosenTemplate
		local chosenUpdateExisting
		local showTokenReference = false

		LrFunctionContext.callWithContext("SnapshotNameDialog", function(dialogContext)
			local f = LrView.osFactory()
			local props = LrBinding.makePropertyTable(dialogContext)

			props.template = currentTemplate
			props.updateExisting = currentUpdateExisting
			props.actionEnabled = trim(currentTemplate) ~= ""

			local preview = f:static_text {
				title = "",
				width = 440,
				truncation = "tail",
			}

			local function refreshPreview()
				local template = trim(props.template)
				props.actionEnabled = template ~= ""

				if template == "" then
					preview.title = "(enter a snapshot name)"
					return
				end

				local expanded = TokenExpander.expand(template, photoData[1] or {}, 1, #photos, now)
				if trim(expanded) == "" then
					preview.title = "(expands to an empty name for the first photo)"
				else
					preview.title = expanded
				end
			end

			props:addObserver("template", refreshPreview)
			refreshPreview()

			local contents = f:column {
				bind_to_object = props,
				spacing = f:dialog_spacing(),

				f:row {
					spacing = f:control_spacing(),
					f:static_text {
						title = "Snapshot name:",
						alignment = "right",
						width = LrView.share("snapshotLabelWidth"),
					},
					f:edit_field {
						value = LrView.bind("template"),
						immediate = true,
						width_in_chars = 52,
					},
				},

				f:row {
					spacing = f:control_spacing(),
					f:static_text {
						title = "Preview:",
						alignment = "right",
						width = LrView.share("snapshotLabelWidth"),
					},
					preview,
				},

				f:static_text {
					title = "Use tokens such as {filename}, {date}, and {sequence}. Use Token Reference for the full list.",
					size = "small",
				},

				f:checkbox {
					title = "Replace an existing snapshot with the same name",
					value = LrView.bind("updateExisting"),
				},
			}

			local result = LrDialogs.presentModalDialog {
				title = string.format("Create Snapshots - %d %s", #photos, plural(#photos, "photo")),
				contents = contents,
				actionVerb = "Create Snapshots",
				cancelVerb = "Cancel",
				otherVerb = "Token Reference",
				save_frame = "createSnapshotsDialog",
				actionBinding = {
					enabled = {
						bind_to_object = props,
						key = "actionEnabled",
					},
				},
			}

			if result == "ok" then
				chosenTemplate = trim(props.template)
				chosenUpdateExisting = props.updateExisting == true
			elseif result == "other" then
				currentTemplate = trim(props.template)
				currentUpdateExisting = props.updateExisting == true
				showTokenReference = true
			end
		end)

		if showTokenReference then
			LrDialogs.message("Token Reference", tokenHelpText, "info")
		else
			if chosenTemplate == nil or chosenTemplate == "" then
				return nil
			end

			prefs[PREF_TEMPLATE] = chosenTemplate
			prefs[PREF_UPDATE_EXISTING] = chosenUpdateExisting

			return chosenTemplate, chosenUpdateExisting
		end
	end
end

local function addFailure(failures, data, index, message)
	failures[#failures + 1] = string.format("%s: %s", photoLabel(data, index), message)
end

local function createSnapshots(catalog, photos, photoData, template, updateExisting, now, progress)
	local results = {
		success = 0,
		duplicates = 0,
		videos = 0,
		failures = {},
		canceled = false,
	}

	local actionName = updateExisting and "Update develop snapshots" or "Create develop snapshots"

	local writeResult = catalog:withWriteAccessDo(actionName, function()
		for index, photo in ipairs(photos) do
			if progress:isCanceled() then
				results.canceled = true
				break
			end

			local data = photoData[index] or {}
			progress:setCaption(photoLabel(data, index))
			progress:setPortionComplete(index - 1, #photos)

			if data.isVideo then
				results.videos = results.videos + 1
			else
				local name = trim(TokenExpander.expand(template, data, index, #photos, now))
				if name == "" then
					addFailure(results.failures, data, index, "the name expanded to an empty string")
				else
					local callSucceeded, snapshotResult = LrTasks.pcall(function()
						return photo:createDevelopSnapshot(name, updateExisting)
					end)

					if not callSucceeded then
						addFailure(results.failures, data, index, tostring(snapshotResult))
					elseif snapshotResult == true then
						results.success = results.success + 1
					elseif snapshotResult == false then
						results.duplicates = results.duplicates + 1
					else
						addFailure(results.failures, data, index, "unexpected result: " .. tostring(snapshotResult))
					end
				end
			end

			if index % 5 == 0 then
				LrTasks.yield()
			end
		end
	end, { timeout = 120 })

	if writeResult == "aborted" then
		error("Could not get write access to the catalog. Another operation may be in progress.")
	end

	progress:setPortionComplete(#photos, #photos)
	progress:done()

	return results
end

local function showSummary(results, updateExisting)
	local lines = {}

	if results.success > 0 then
		local verb = updateExisting and "Created or updated" or "Created"
		lines[#lines + 1] = string.format(
			"%s %d %s.",
			verb,
			results.success,
			plural(results.success, "snapshot")
		)
	else
		lines[#lines + 1] = "No snapshots were created."
	end

	if results.duplicates > 0 then
		lines[#lines + 1] = string.format(
			"Skipped %d %s because a snapshot with that name already exists.",
			results.duplicates,
			plural(results.duplicates, "photo")
		)
	end

	if results.videos > 0 then
		lines[#lines + 1] = string.format(
			"Skipped %d %s (Develop snapshots apply to photos, not videos).",
			results.videos,
			plural(results.videos, "video")
		)
	end

	if results.canceled then
		lines[#lines + 1] = "Canceled. Snapshots completed before cancellation were kept."
	end

	if #results.failures > 0 then
		lines[#lines + 1] = string.format("%d %s:", #results.failures, plural(#results.failures, "failure"))

		local shown = math.min(#results.failures, 8)
		for index = 1, shown do
			lines[#lines + 1] = "  " .. results.failures[index]
		end
		if #results.failures > shown then
			lines[#lines + 1] = string.format("  ...and %d more.", #results.failures - shown)
		end
	end

	lines[#lines + 1] = "Find snapshots in the Develop module's Snapshots panel."

	local style = "info"
	if #results.failures > 0 then
		style = "warning"
	end

	LrDialogs.message("Create Snapshots", table.concat(lines, "\n"), style)
end

LrFunctionContext.postAsyncTaskWithContext("LRC Snapshot", function(context)
	LrDialogs.attachErrorDialogToFunctionContext(context)

	local catalog = LrApplication.activeCatalog()
	local photos = catalog:getTargetPhotos()

	if catalog:getTargetPhoto() == nil or #photos == 0 then
		LrDialogs.message(
			"No photos selected",
			"Select one or more photos, then run Create Snapshots for Selected Photos again.",
			"info"
		)
		return
	end

	local photoData = buildPhotoData(catalog, photos)
	local now = LrDate.currentTime()

	local template, updateExisting = promptForOptions(photos, photoData, now)
	if template == nil then
		return
	end

	local progress = LrProgressScope {
		title = "Creating Snapshots",
		caption = "Preparing...",
		functionContext = context,
	}
	progress:setCancelable(true)

	local results = createSnapshots(catalog, photos, photoData, template, updateExisting, now, progress)
	showSummary(results, updateExisting)
end)
