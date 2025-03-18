local colorGroups = 1 -- amount of different color groups you want it to have (less groups means less precision)


local administerGUI = game.ServerScriptService.Administer.Resources.AdministerMainPanel

local administerGUIObjects = {}

function reverseTable(t)
	local reversed = {}
	for i = #t, 1, -1 do
		reversed[#reversed + 1] = t[i]
	end
	return reversed
end

function colorSequenceToRGB(colorSequence: ColorSequence)
	local rgb = {}
	for _, keypoint in colorSequence.Keypoints do
		table.insert(rgb, {math.floor(keypoint.Value.R * 255), math.floor(keypoint.Value.G * 255), math.floor(keypoint.Value.B * 255)})
	end
	return rgb
end

local function arrayContainsTable(input: {}): boolean
	for i, entry in input do
		if typeof(entry) == "table" then
			return true
		end
	end

	return false
end

local function RGBToColorSequence(rgbList: {{R: number, G: number, B: number}})
	local keypoints = {}
	for i, rgb in rgbList do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#rgbList - 1), Color3.fromRGB(rgb[1], rgb[2], rgb[3])))
	end
	return ColorSequence.new(keypoints)
end

function color3ToRGB(color3)
	return {
		math.floor(color3.R * 255),
		math.floor(color3.G * 255),
		math.floor(color3.B * 255)
	}
end

function rgbToColor3(rgb)
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local descendants = administerGUI:GetDescendants()
for i, object in descendants do
	if object:IsA("GuiObject") then
		local rgb, rgbStr
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			rgb = color3ToRGB(object.ImageColor3)
		else
			rgb = color3ToRGB(object.BackgroundColor3)
		end

		if type(rgb[1]) == "table" then
			rgbStr = ""
			for j = 1, #rgb do
				rgbStr = rgbStr .. table.concat(rgb[j], ",") .. ";"
			end
		else
			rgbStr = table.concat(rgb, ",")
		end

		if not administerGUIObjects[rgbStr] then
			administerGUIObjects[rgbStr] = { rgb, {} }
		end
		local objectList = administerGUIObjects[rgbStr][2]
		objectList[#objectList + 1] = {object}
	elseif object:IsA("UIGradient") then
		local colors = colorSequenceToRGB(object.Color)
		for i, rgb in colors do
			if type(rgb[1]) == "table" then
				rgbStr = ""
				for j = 1, #rgb do
					rgbStr = rgbStr .. table.concat(rgb[j], ",") .. ";"
				end
			else
				rgbStr = table.concat(rgb, ",")
			end

			if not administerGUIObjects[rgbStr] then
				administerGUIObjects[rgbStr] = { rgb, {} }
			end
			local objectList = administerGUIObjects[rgbStr][2]
			objectList[#objectList + 1] = {object, i}
		end
	end
end

local function random_color()
	return {
		math.random(0, 255),
		math.random(0, 255),
		math.random(0, 255)
	}
end

local function euclidean_distance(c1, c2)
	return math.sqrt((c1[1] - c2[1])^2 + (c1[2] - c2[2])^2 + (c1[3] - c2[3])^2)
end

local function find_closest_cluster(color, centroids)
	local min_dist, cluster_index = math.huge, 1
	for i, v in centroids do
		local dist = euclidean_distance(color, centroids[i])
		if dist < min_dist then
			min_dist = dist
			cluster_index = i
		end
	end
	return cluster_index
end

local function compute_new_centroids(colors, clusters, k)
	local sums, counts = {}, {}
	for i = 1, k do
		sums[i] = { 0, 0, 0 }
		counts[i] = 0
	end

	for i, v in colors do
		local cluster = clusters[i]
		if cluster then
			local color = v
			sums[cluster][1] = sums[cluster][1] + color[1]
			sums[cluster][2] = sums[cluster][2] + color[2]
			sums[cluster][3] = sums[cluster][3] + color[3]
			counts[cluster] = counts[cluster] + 1
		end
	end

	local new_centroids = {}
	for i = 1, k do
		if counts[i] > 0 then
			new_centroids[i] = {
				math.floor(sums[i][1] / counts[i]),
				math.floor(sums[i][2] / counts[i]),
				math.floor(sums[i][3] / counts[i])
			}
		else
			new_centroids[i] = random_color()
		end
	end
	return new_centroids
end

local function kmeans(colors, k, max_iters)
	local centroids, clusters = {}, {}
	for i = 1, k do
		centroids[i] = colors[math.random(1, #colors)]
	end

	for iter = 1, max_iters do
		local changes = 0
		for i, color in colors do
			if arrayContainsTable(color) then
				for k, w in color do
					local cluster = find_closest_cluster(w, centroids)
					if clusters[k] ~= cluster then
						clusters[k] = cluster
						changes = changes + 1
					end
				end
			else
				local cluster = find_closest_cluster(color, centroids)
				if clusters[i] ~= cluster then
					clusters[i] = cluster
					changes = changes + 1
				end
			end
		end

		centroids = compute_new_centroids(colors, clusters, k)

		if changes == 0 then
			break
		end
	end

	return clusters, centroids
end

local colorTable, colorLookup, index = {}, {}, 1

local keys = {}
for key in next, administerGUIObjects do
	keys[#keys + 1] = key
end

for i, v in keys do
	colorTable[index] = administerGUIObjects[v][1]
	colorLookup[index] = v
	index = index + 1
end

local k, max_iters = colorGroups, 750
local clusters, centroids = kmeans(colorTable, k, max_iters)

local newColors = {}

for i, v in clusters do
	local rgbStr = colorLookup[i]
	local newColor = centroids[clusters[i]]

	if not newColors[rgbStr] then
		newColors[rgbStr] = newColor
	end
end

local UIGradientData = {}

for _, v in keys do
	local rgbStr = v
	local data = administerGUIObjects[rgbStr]
	local newColor = newColors[rgbStr]

	if newColor then
		local objects = data[2]
		for k, w in objects do
			local item = w[1]
			--// hi sorry i needed to work normally so feel free to uncomment :3
			if item:IsA("ImageLabel") or item:IsA("ImageButton") then
				--item.ImageColor3 = rgbToColor3(newColor)
			elseif item:IsA("UIGradient") then
				local keypointPosition = objects[k][2]
				if not UIGradientData[item] then UIGradientData[item] = {} end
				table.insert(UIGradientData[item], keypointPosition, newColor)
			else
				--item.BackgroundColor3 = rgbToColor3(newColor)
			end
		end
	end
end

for i, v in UIGradientData do
	local colorList = v
	local colorSequence = RGBToColorSequence(colorList)
	i.Color = colorSequence
end
