--[[
	TokenExpander.lua
	Expands snapshot-name tokens for one photo.
]]

local LrDate = import "LrDate"
local LrPathUtils = import "LrPathUtils"

local TokenExpander = {}

local function dateParts(timestamp)
	if type(timestamp) ~= "number" then
		return nil
	end

	local year, month, day, hour, minute, second = LrDate.timestampToComponents(timestamp)
	return {
		year = year,
		month = month,
		day = day,
		hour = hour,
		minute = minute,
		second = second,
	}
end

local function formatDate(parts)
	if not parts then
		return ""
	end
	return string.format("%04d-%02d-%02d", parts.year, parts.month, parts.day)
end

local function formatTime(parts)
	if not parts then
		return ""
	end
	return string.format("%02d-%02d-%02d", parts.hour, parts.minute, parts.second)
end

local function formatDateTime(parts)
	if not parts then
		return ""
	end
	return formatDate(parts) .. "_" .. formatTime(parts)
end

local function fileNameFor(data)
	if data.fileName and data.fileName ~= "" then
		return data.fileName
	end
	if data.path and data.path ~= "" then
		local name = LrPathUtils.leafName(data.path)
		if name then
			return name
		end
	end
	return ""
end

local function formatAperture(value)
	if type(value) ~= "number" then
		return ""
	end
	return string.format("f/%g", value)
end

local function formatShutter(value)
	if type(value) ~= "number" or value <= 0 then
		return ""
	end
	if value >= 0.5 then
		return string.format("%gs", value)
	end

	local denominator = math.floor((1 / value) + 0.5)
	if denominator < 1 then
		denominator = 1
	end
	return string.format("1/%ds", denominator)
end

local function formatIso(value)
	if type(value) ~= "number" then
		return ""
	end
	return string.format("ISO %g", value)
end

local function formatFocalLength(value)
	if type(value) ~= "number" then
		return ""
	end
	return string.format("%gmm", value)
end

local function formatRating(value)
	if type(value) ~= "number" or value == 0 then
		return "unrated"
	end
	return tostring(value)
end

local function formatLabel(value)
	if value == nil or value == "" then
		return "none"
	end
	return value
end

local function resolve(token, data, index, total, nowParts)
	if token == "filename" then
		return fileNameFor(data)
	elseif token == "filename_noext" then
		local name = fileNameFor(data)
		if not name or name == "" then
			return ""
		end
		return LrPathUtils.removeExtension(name)
	elseif token == "ext" then
		local name = fileNameFor(data)
		if not name or name == "" then
			return ""
		end
		return LrPathUtils.extension(name)
	elseif token == "folder" then
		return data.folder or ""
	elseif token == "camera" then
		return data.cameraModel or data.cameraMake or ""
	elseif token == "lens" then
		return data.lens or ""
	elseif token == "iso" then
		return formatIso(data.iso)
	elseif token == "aperture" then
		return formatAperture(data.aperture)
	elseif token == "shutter" then
		return formatShutter(data.shutter)
	elseif token == "focal_length" then
		return formatFocalLength(data.focalLength)
	elseif token == "rating" then
		return formatRating(data.rating)
	elseif token == "label" then
		return formatLabel(data.label)
	elseif token == "capture_date" then
		return formatDate(dateParts(data.captureTime))
	elseif token == "capture_time" then
		return formatTime(dateParts(data.captureTime))
	elseif token == "capture_datetime" then
		return formatDateTime(dateParts(data.captureTime))
	elseif token == "date" then
		return formatDate(nowParts)
	elseif token == "time" then
		return formatTime(nowParts)
	elseif token == "datetime" then
		return formatDateTime(nowParts)
	elseif token == "sequence" then
		return tostring(index or 1)
	elseif token == "total" then
		return tostring(total or 1)
	end

	-- Unknown tokens are left untouched so typos remain visible in the preview.
	return nil
end

-- Expands {tokens} in a snapshot-name template. Use {{ and }} for literal braces.
function TokenExpander.expand(template, data, index, total, now)
	if type(template) ~= "string" then
		return ""
	end

	data = data or {}
	local nowParts = dateParts(now or LrDate.currentTime())

	local expanded = template
	expanded = expanded:gsub("{{", "\1")
	expanded = expanded:gsub("}}", "\2")

	expanded = expanded:gsub("{([%w_]+)}", function(token)
		local value = resolve(token:lower(), data, index, total, nowParts)
		if value == nil then
			return nil
		end
		return tostring(value)
	end)

	expanded = expanded:gsub("\1", "{")
	expanded = expanded:gsub("\2", "}")
	return expanded
end

TokenExpander.tokenGroups = {
	{
		title = "Photo",
		tokens = {
			{ token = "{filename}", description = "File name" },
			{ token = "{filename_noext}", description = "Name without extension" },
			{ token = "{ext}", description = "File extension" },
			{ token = "{folder}", description = "Folder name" },
			{ token = "{camera}", description = "Camera model" },
			{ token = "{lens}", description = "Lens" },
			{ token = "{iso}", description = "ISO, e.g. ISO 400" },
			{ token = "{aperture}", description = "Aperture, e.g. f/2.8" },
			{ token = "{shutter}", description = "Shutter, e.g. 1/250s" },
			{ token = "{focal_length}", description = "Focal length, e.g. 50mm" },
			{ token = "{rating}", description = "Star rating" },
			{ token = "{label}", description = "Color label" },
		},
	},
	{
		title = "Dates and selection",
		tokens = {
			{ token = "{capture_date}", description = "Capture date" },
			{ token = "{capture_time}", description = "Capture time" },
			{ token = "{capture_datetime}", description = "Capture date and time" },
			{ token = "{date}", description = "Today's date" },
			{ token = "{time}", description = "Current time" },
			{ token = "{datetime}", description = "Current date and time" },
			{ token = "{sequence}", description = "Position in selection" },
			{ token = "{total}", description = "Number of selected photos" },
		},
	},
}

return TokenExpander
