-- ========================================================================= --
--                              SylingTracker                                --
--           https://www.curseforge.com/wow/addons/sylingtracker             --
--                                                                           --
--                               Repository:                                 --
--                   https://github.com/Skamer/SylingTracker                 --
--                                                                           --
-- ========================================================================= --
Syling                     "SylingTracker.Core.Button"                       ""
-- ========================================================================= --
class "Button" { Scorpio.UI.Button }

UI.Property         {
    name            = "NormalTexture",
    type            = Texture,
    require         = Button,
    nilable         = true,
    childtype       = Texture,
    clear           = Button.ClearNormalTexture and function(self) self:ClearNormalTexture() end,
    set             = function(self, val) self:SetNormalTexture(val) end,
}