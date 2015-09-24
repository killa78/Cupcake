-----------------------------------------------------------------------------------------------
-- Client Lua Script for Cupcake
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Cupcake Module Definition
-----------------------------------------------------------------------------------------------
local Cupcake = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
local tSettings									= {}
	tSettings.lfgShouldConnect					= "true"
	tSettings.genShouldConnect					= "true"
	tSettings.version							= "1.0"
	tSettings.Loaded                            = "false"
---------------------------------------------------------
local tExile									= Unit.CodeEnumFaction.ExilesPlayer
local tDominion									= Unit.CodeEnumFaction.DominionPlayer
---------------------------------------------------------
local tServerChannelLists						= {}
	
	tServerChannelLists.Entity					= {}
	tServerChannelLists.Entity.Exile 			= {}
	tServerChannelLists.Entity.Exile.LFG 		= "Lfg"
	tServerChannelLists.Entity.Exile.GEN 		= "General" 
	tServerChannelLists.Entity.Dominion 		= {}
	tServerChannelLists.Entity.Dominion.LFG 	= "EntityLFM"
	tServerChannelLists.Entity.Dominion.GEN 	= "EntityChat"
	
	tServerChannelLists.Warhound 				= {}
	tServerChannelLists.Warhound.Exile 		= {}
	tServerChannelLists.Warhound.Exile.LFG 	= "Lfg"
	tServerChannelLists.Warhound.Exile.GEN 	= "General"
	tServerChannelLists.Warhound.Dominion 	= {}
	tServerChannelLists.Warhound.Dominion.LFG = "WarhoundLFM"
	tServerChannelLists.Warhound.Dominion.GEN = "WarhoundChat"
	
	tServerChannelLists.Jabbit 					= {}
	tServerChannelLists.Jabbit.Exile 			= {}
	tServerChannelLists.Jabbit.Exile.LFG 		= "Lfg"
	tServerChannelLists.Jabbit.Exile.GEN 		= "General"
	tServerChannelLists.Jabbit.Dominion 		= {}
	tServerChannelLists.Jabbit.Dominion.LFG 	= "Lfg"
	tServerChannelLists.Jabbit.Dominion.GEN 	= "General"	
	
	tServerChannelLists.Luminai 				= {}
	tServerChannelLists.Luminai.Exile 		= {}
	tServerChannelLists.Luminai.Exile.LFG 	= "Lfg"
	--tServerChannelLists.Luminai.Exile.GEN 	= "General"
	tServerChannelLists.Luminai.Dominion 		= {}
	tServerChannelLists.Luminai.Dominion.LFG 	= "Lfg"
	tServerChannelLists.Luminai.Dominion.GEN 	= "General"
	
	tServerChannelLists.Nexus 					= {}
	tServerChannelLists.Nexus.Exile 			= {}
	tServerChannelLists.Nexus.Exile.LFG 		= "Lfg"
	tServerChannelLists.Nexus.Exile.GEN 		= "General"
	tServerChannelLists.Nexus.Dominion 		= {}
	tServerChannelLists.Nexus.Dominion.LFG 	= "Lfg"
	tServerChannelLists.Nexus.Dominion.GEN 	= "General"
----------------------------------------------------------
	
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Cupcake:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Cupcake:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Cupcake OnLoad
-----------------------------------------------------------------------------------------------
function Cupcake:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Cupcake.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Cupcake OnDocLoaded
-----------------------------------------------------------------------------------------------
function Cupcake:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "CupcakeForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("cupcake", "OnCupcakeOn", self)
		
		
		-- Do additional Addon initialization here
		self.ChatChannels = {}
		self.iMyFaction = ""
		self.strMyRealm = ""
		self.bConnectedToLFG = ""
		self.bConnectedToGEN = ""
		self.lfgSlashCommand = ""
		self.genSlashCommand = ""
		self:SetupCheckboxes()
		self:SetupChatBoxes()
		self:GetChatChannels()
		--self:JoinChatChannels()
		self:DoChannelUpdate()
		self.UpdateTimer = ApolloTimer.Create(15.0,true,"DoChannelUpdate",self)
	end
end
-----------------------------------------------------------------------------------------------
-- Cupcake OnSave/Load Functions
-----------------------------------------------------------------------------------------------
function Cupcake:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end
    return  tSettings
end

function Cupcake:OnRestore(eLevel, tSaveData)
	if tSettings then
		tSettings = tSaveData
	end
  
end 
-----------------------------------------------------------------------------------------------
-- Cupcake Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/cupcake"
function Cupcake:OnCupcakeOn()
self:DoChannelUpdate()
	self.wndMain:Invoke() -- show the window
	SendVarToRover("tSettings",tSettings)
end

function Cupcake:SetupCheckboxes()
	if tSettings.lfgShouldConnect == "true" then
		self.wndMain:FindChild("lfgConnectCheckBox"):SetCheck(tSettings.lfgShouldConnect)
	end
	
	if tSettings.genShouldConnect == "true" then
		self.wndMain:FindChild("genConnectCheckBox"):SetCheck(tSettings.lfgShouldConnect)
	end
end

function Cupcake:SetupChatBoxes()
	self.iMyFaction = GameLib.GetPlayerUnit():GetFaction()
	self.strMyRealm = GameLib.GetRealmName()
	if self.iMyFaction == tExile then
		self.wndMain:FindChild("lfgNamePlate"):SetText(tServerChannelLists[self.strMyRealm].Exile.LFG)
		self.wndMain:FindChild("genNamePlate"):SetText(tServerChannelLists[self.strMyRealm].Exile.GEN)
	elseif self.iMyFaction == tDominion then
		self.wndMain:FindChild("lfgNamePlate"):SetText(tServerChannelLists[self.strMyRealm].Dominion.LFG)
		self.wndMain:FindChild("genNamePlate"):SetText(tServerChannelLists[self.strMyRealm].Dominion.GEN)
	end
end

function Cupcake:GetChatChannels()
local strForChannelName = ""
 self.ChatChannels = ChatSystemLib.GetChannels()
	for key, value in pairs(self.ChatChannels) do
		strForChannelName = value:GetName()
		if self.iMyFaction == tExile then
			if strForChannelName:lower() == string.lower(tServerChannelLists[self.strMyRealm].Exile.LFG) then
				self.bConnectedToLFG = "true"
				self.lfgSlashCommand = value:GetCommand()
			elseif strForChannelName:lower() == string.lower(tServerChannelLists[self.strMyRealm].Exile.GEN) then
				self.bConnectedToGEN = "true"
				self.genSlashCommand = value:GetCommand()
			end
		elseif self.iMyFaction == tDominion then
			if strForChannelName.lower() == string.lower(tServerChannelLists[self.strMyRealm].Dominion.LFG) then
				self.bConnectedToLFG = "true"
				self.lfgSlashCommand = "/".. value:GetCommand()
			elseif strForChannelName.lower() == string.lower(tServerChannelLists[self.strMyRealm].Dominion.GEN) then
				self.bConnectedToGEN = "true"
				self.genSlashCommand = value:GetCommand()
			end
	    end 
	end
end

function Cupcake:JoinChatChannels()
	if tSettings.lfgShouldConnect == "true" then
		if self.bConnectedToLFG == "true" then
		else
			if self.iMyFaction == tExile then
				ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Exile.LFG)
			elseif self.iMyFaction == tDominion then
				ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Dominion.LFG)
			end	
		end
	end

	if tSettings.genShouldConnect == "true" then
		if self.bConnectedToGEN == "true" then
		else
			if self.iMyFaction == tExile then
					ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Exile.GEN)
			elseif self.iMyFaction == tDominion then
					ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Dominion.GEN)
			end	
		end
	end
end

function Cupcake:DoChannelUpdate(bWipe) 
		self.bConnectedToLFG = "false"
		self.bConnectedToGEN = "false"
		self:GetChatChannels()
		if self.bConnectedToLFG == "true" then 
			self.wndMain:FindChild("lfgButton"):SetBGColor("AttributeMagic")
			self.wndMain:FindChild("lfgSlashBox"):SetText("/" .. self.lfgSlashCommand)
		else
			self.wndMain:FindChild("lfgButton"):SetBGColor("AttributeStamina")
			self.wndMain:FindChild("lfgSlashBox"):SetText("")
		end
		
		if self.bConnectedToGEN == "true" then
			self.wndMain:FindChild("genButton"):SetBGColor("AttributeMagic")
			self.wndMain:FindChild("genSlashBox"):SetText("/" .. self.genSlashCommand)
		else
			self.wndMain:FindChild("genButton"):SetBGColor("AttributeStamina")
			self.wndMain:FindChild("genSlashBox"):SetText("")
		end
end


-----------------------------------------------------------------------------------------------
-- CupcakeForm Functions
-----------------------------------------------------------------------------------------------
--- When the Chat Channel Checkboxes are Checked
function Cupcake:OnCheckBox( wndHandler, wndControl, eMouseButton )
	if wndHandler:GetName() == "lfgConnectCheckBox" then
		tSettings.lfgShouldConnect = "true"
		self.bConnectedToLFG = "true"
			if self.iMyFaction == tExile then
				ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Exile.LFG)
			elseif self.iMyFaction == tDominion then
				ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Dominion.LFG)
			end	
	--	self:DoChannelUpdate(false)
	elseif wndHandler:GetName() == "genConnectCheckBox" then
		tSettings.genShouldConnect = "true"
		self.bConnectedToGEN = "true"
			if self.iMyFaction == tExile then
				ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Exile.GEN)
			elseif self.iMyFaction == tDominion then
				ChatSystemLib.Command("/chjoin " .. tServerChannelLists[self.strMyRealm].Dominion.GEN)
			end	
	--	self:DoChannelUpdate(false)
	else
		return
	end
end
--- When the Chat Channel Checkboxes is Unchecked 
function Cupcake:OnUncheckBox( wndHandler, wndControl, eMouseButton )
	if wndHandler:GetName() == "lfgConnectCheckBox" then		
		tSettings.lfgShouldConnect = "false"
		self.bConnectedToLFG = "false"
		ChatSystemLib.Command("/chleave ".. self.lfgSlashCommand)
	--	self:DoChannelUpdate(false)
	elseif wndHandler:GetName() == "genConnectCheckBox" then
		tSettings.genShouldConnect = "false"
		self.bConnectedToGEN = "false"
		ChatSystemLib.Command("/chleave ".. self.genSlashCommand)
	--	self:DoChannelUpdate(false)
	else
		return
	end
end



function Cupcake:OnCancel( wndHandler, wndControl, eMouseButton )
	self.wndMain:Show(false,true)
end

-----------------------------------------------------------------------------------------------
-- Cupcake Instance
-----------------------------------------------------------------------------------------------
local CupcakeInst = Cupcake:new()
CupcakeInst:Init()
