-- Tell me when the remote has commits I do not.
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local is_git = os.execute("git rev-parse --is-inside-work-tree > /dev/null 2>&1")
		if is_git ~= 0 then
			return
		end

		-- Fetch asynchronously so startup does not wait on the network.
		vim.fn.jobstart("git fetch", {
			on_exit = function()
				local count = vim.fn.system("git rev-list --count HEAD..@{u} 2>/dev/null"):gsub("%s+", "")

				if count ~= "" and tonumber(count) > 0 then
					vim.schedule(function()
						vim.notify(
							"󰊢 " .. count .. " new commit(s) available on remote.",
							vim.log.levels.INFO,
							{ title = "Git Status", icon = "󰊢" }
						)
					end)
				end
			end,
		})
	end,
})

-- Cursorline only in the focused window.
local cursorline_group = vim.api.nvim_create_augroup("CursorLineControl", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = cursorline_group,
	callback = function()
		vim.opt_local.cursorline = true
	end,
})

vim.api.nvim_create_autocmd({ "WinLeave" }, {
	group = cursorline_group,
	callback = function()
		vim.opt_local.cursorline = false
	end,
})

local group = vim.api.nvim_create_augroup("autosave", {})

-- Say when a file is saved by autosave.
vim.api.nvim_create_autocmd("User", {
	pattern = "AutoSaveWritePre",
	group = group,
	callback = function(opts)
		if opts.data.saved_buffer ~= nil then
			local filename = vim.fn.expand("%:t")
			print("Saved '" .. filename .. "' at " .. vim.fn.strftime("%H:%M:%S"))
		end
	end,
})

vim.api.nvim_create_autocmd("User", {
	pattern = "AutoSaveEnable",
	group = group,
	callback = function()
		print("AutoSave enabled")
	end,
})

vim.api.nvim_create_autocmd("User", {
	pattern = "AutoSaveDisable",
	group = group,
	callback = function()
		print("AutoSave disabled")
	end,
})

-- Centre the cursor when insert mode starts, which keeps scrollEOF from
-- fighting the scrolloff setting.
vim.api.nvim_create_autocmd("InsertEnter", {
	callback = function()
		vim.cmd("normal! zz")
	end,
})
