--!strict
-- core/notify.luau
local S = ModMenu.Services
local StarterGui = S.StarterGui

ModMenu.Notify = function(title: string, text: string, duration: number?)
	duration = duration or 4
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration,
		})
	end)
end
