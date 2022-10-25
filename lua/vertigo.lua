local namespace = vim.api.nvim_create_namespace("Vertigo")

vim.api.nvim_set_hl(0, "VertigoLabels", { default = true, link = "CursorLineNr" })

local opts = {
	prefix_keys = { "", ",", ";", ":", "!", "_", "<" },
	-- stylua: ignore
	target_keys = {
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
		"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	},
}

--- Helpers ----------------------------------------------------------------------------------------

local function valid_list(value, check_func)
	if type(value) ~= "table" then
		return false
	elseif type(check_func) == "function" then
		return #value > 0 and #vim.tbl_filter(check_func, value) == #value
	else
		return #value > 0
	end
end

local function warn(message, ...)
	if ... then
		message = string.format(message, ...)
	end
	vim.notify(message, vim.log.levels.WARN)
end

--- Checks -----------------------------------------------------------------------------------------

local function valid_prefix_keys(prefix_keys)
	return valid_list(prefix_keys, function(v)
		return type(v) == "string" and #v < 2
	end)
end

local function valid_target_keys(target_keys)
	return valid_list(target_keys, function(v)
		return type(v) == "string" and #v == 1
	end)
end

--- Core -------------------------------------------------------------------------------------------

local function generate_labels(prefix_keys, target_keys)
	local combinations_count = #prefix_keys * #target_keys

	local prefix_key, target_key
	local cycling_targets = table.concat(target_keys, "")

	local labels = {}

	for i = 1, combinations_count do
		prefix_key = prefix_keys[math.ceil(i / #target_keys)]
		target_key = cycling_targets:sub(1, 1)
		table.insert(labels, prefix_key .. target_key)

		cycling_targets = cycling_targets:sub(2) .. target_key
	end

	return labels
end
opts.labels = generate_labels(opts.prefix_keys, opts.target_keys)

local function get_targets(win_id, labels, direction)
	local lbound_line = vim.fn.line("w0", win_id)
	local ubound_line = vim.fn.line("w$", win_id)
	local cursor_line = vim.api.nvim_win_get_cursor(win_id)[1]

	if direction == "above" then
		ubound_line = cursor_line
	elseif direction == "below" then
		lbound_line = cursor_line
	end

	local abs_offset, label, direction_key, target_key, keys_sequence

	local mode = vim.api.nvim_get_mode().mode
	local operation_key = mode:find("o") and vim.v.operator or ""

	local targets = {}

	for line_number = lbound_line, ubound_line do
		abs_offset = math.abs(line_number - cursor_line)
		if abs_offset > 0 and abs_offset <= #labels then
			label = labels[abs_offset]
			direction_key = line_number < cursor_line and "k" or "j"

			target_key = ("%s%s"):format(label, direction_key)
			keys_sequence = ("%s%s%s"):format(operation_key, abs_offset, direction_key)

			targets[target_key] = { text = label, line = line_number, keys = keys_sequence }
		end
	end

	return targets
end

local function ask_for_label(prefix_keys, labels)
	local label = ""
	local current_key = ""

	local allowed_prefix = {}
	for _, prefix_key in ipairs(prefix_keys) do
		allowed_prefix[prefix_key] = true
	end

	for _ = 1, 2 do
		_, current_key = pcall(vim.fn.getcharstr)
		label = label .. current_key

		if not allowed_prefix[current_key] then
			break
		end
	end

	if vim.tbl_contains(labels, label) then
		return label
	end
end

local function ask_for_direction()
	local _, current_key = pcall(vim.fn.getcharstr)
	if current_key == "k" then
		return "above"
	elseif current_key == "j" then
		return "below"
	else
		return
	end
end

local function clear_labels(buf_nr)
	vim.api.nvim_buf_clear_namespace(buf_nr, namespace, 0, -1)
end

local function show_labels(buf_nr, targets)
	local number_width = math.max(vim.wo.numberwidth, 3)
	local label_fmt = ("%%%ss"):format(number_width - 1)

	clear_labels(buf_nr)

	for _, label in pairs(targets) do
		vim.api.nvim_buf_set_extmark(buf_nr, namespace, label.line - 1, 0, {
			virt_text = { { label_fmt:format(label.text), "VertigoLabels" } },
			virt_text_pos = "overlay",
			virt_text_win_col = -number_width,
		})
	end

	vim.cmd("redraw")
end

local function send_keys(keys_sequence)
	if type(keys_sequence) == "string" then
		vim.api.nvim_feedkeys(keys_sequence, "n", true)
	end
end

----------------------------------------------------------------------------------------------------

local function main(direction)
	local win_id = vim.api.nvim_get_current_win()
	local buf_nr = vim.api.nvim_win_get_buf(win_id)

	local targets = get_targets(win_id, opts.labels, direction)

	show_labels(buf_nr, targets)
	local label = ask_for_label(opts.prefix_keys, opts.labels)
	clear_labels(buf_nr)

	if label == nil then
		return
	end

	if direction ~= "above" and direction ~= "below" then
		direction = ask_for_direction()
	end

	if direction == nil then
		return
	end
	direction = direction == "above" and "k" or "j"

	local target = targets[label .. direction]
	if type(target) == "table" then
		send_keys(target.keys)
	end
end

--- Exported ---------------------------------------------------------------------------------------

local M = {}

function M.setup(user_opts)
	if type(user_opts) ~= "table" then
		return
	end

	if user_opts.prefix_keys ~= nil and not valid_prefix_keys(opts.prefix_keys) then
		return warn("'prefix_keys' must be a list of characters with at least one element.")
	end

	if user_opts.target_keys ~= nil and not valid_target_keys(opts.target_keys) then
		return warn("'target_keys' must be a list of characters with at least one element.")
	end

	opts = vim.tbl_extend("force", opts, user_opts)
	opts.labels = generate_labels(opts.prefix_keys, opts.target_keys)
end

function M.jump_to_line_above()
	main("above")
end

function M.jump_to_line_below()
	main("below")
end

function M.jump_to_line()
	main()
end

return M
