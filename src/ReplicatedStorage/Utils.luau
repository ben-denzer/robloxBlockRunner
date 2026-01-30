local function formatCash(amount)
	local str = tostring(math.floor(amount))
	local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	-- Remove leading comma if present
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

return {
	formatCash = formatCash,
}
