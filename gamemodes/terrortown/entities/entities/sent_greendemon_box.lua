---@diagnostic disable: duplicate-set-field, undefined-field, inject-field
if SERVER then
	AddCSLuaFile()
	resource.AddFile("sound/weapons/ttt_spring_mine/sm64_mario_boing2.wav")
	resource.AddFile("materials/vgui/ttt/weapon_ttt_greendemon.png")
	resource.AddFile("models/entities/entities/sent_greendemon_box/box.mdl")
	resource.AddFile("materials/models/entities/entities/sent_greendemon_box/default.vmt")
	resource.AddFile("materials/models/entities/entities/sent_greendemon/gd.png")
	resource.AddFile("materials/models/entities/entities/sent_greendemon/gd_glint.vmf")
	resource.AddFile("materials/models/entities/entities/sent_greendemon/gd_glint.vtf")
	resource.AddFile("materials/models/entities/entities/sent_greendemon/shadowtex.png")
end

ENT.Icon = "vgui/ttt/weapon_ttt_greendemon.png"
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Projectile = true
ENT.CanHavePrints = true

-- ENT.Model = Model("models/props_phx/smallwheel.mdl")
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Model = Model("models/entities/entities/sent_greendemon_box/box.mdl")
-- ENT.Color = Color(0,0,0,255)
ENT.ArmTime = 0.125
ENT.SpawnHeight = 66
ENT.Color = Color(255,255,255,32)

function ENT:Initialize()
	self:SetModel(self.Model)
	-- self:SetMaterial("models/entities/entities/sent_greendemon_box/default")
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetColor(self.Color)
	self:DrawShadow( false )

	-- self:SetColor(self.Color)

	self:PhysicsInit(SOLID_VPHYSICS)
	-- self:SetModelScale(0.125, 0.000001)
	-- self:Activate()
	-- self:SetColor(self.Color)
	-- self:SetHealth(25)

	-- if SERVER then
	-- 	Resize(self, 0.125)
	-- 	self:PhysicsInit(SOLID_VPHYSICS)
	-- 	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	-- 	self:GetPhysicsObject():SetMass(43)
	-- end
	if SERVER then
		self:SetTrigger(true)
		self:NextThink(CurTime() + self.ArmTime)
		self.SpawnTime = CurTime()
		markerVision.RegisterEntity(self, self:GetOwner(), VISIBLE_FOR_TEAM)
	end

---@diagnostic disable-next-line: undefined-field
	return self.BaseClass.Initialize(self)
end

if SERVER then
	function ENT:Think()
		if (not self.Solidified and CurTime() > (self.SpawnTime + self.ArmTime)) then
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self.Solidified = true
		end
	end
end

function ENT:SpawnDemon(ply)
	local ent = ents.Create("sent_greendemon")
	if not IsValid(ent) then return end
	ent.activator = ply
	local ep = ply:EyePos() - ply:GetPos()
	ent:SetPos(self:GetPos() + ep)

	local owner = self:GetOwner()
	ent:SetOwner(owner)
	ent:SetPhysicsAttacker(owner --[[@as Player]])
	ent.WeaponConnection = self.WeaponConnection

	ent:Spawn()
	markerVision.RemoveEntity(self)
	self:Remove()
end

function ENT:OnRemove()
	markerVision.RemoveEntity(self)
end

ENT.touched = false
function ENT:StartTouch(ent)
	if (not self.Solidified ) then return end
	if self.touched then return end

	if (ent:IsValid() and ent:IsPlayer()) then
		self.touched = true
		self:SpawnDemon(ent)
	end
end

if CLIENT then
	local greendemonboxMV = Material("vgui/ttt/marker_vision/greendemon_box")

	local TryT = LANG.TryTranslation
	local ParT = LANG.GetParamTranslation

	hook.Add("TTT2RenderMarkerVisionInfo", "HUDDrawMarkerVisionGreenDemonBox", function(mvData)
		local ent = mvData:GetEntity()

		if not IsValid(ent) or ent:GetClass() ~= "sent_greendemon_box" then return end

		local owner = ent:GetOwner()
		local nick = IsValid(owner) and owner:Nick() or "---"

		-- local time = util.SimpleTime(ent:GetExplodeTime() - CurTime(), "%02i:%02i")
		local distance = math.Round(util.HammerUnitsToMeters(mvData:GetEntityDistance()), 1)

		mvData:EnableText()

		mvData:SetTitle(TryT("greendemon_box_name"))

		mvData:AddDescriptionLine(ParT("marker_vision_owner", {owner = nick}))
		mvData:AddDescriptionLine(ParT("marker_vision_distance", {distance = distance}))

		mvData:AddDescriptionLine(TryT("marker_vision_visible_for_" .. markerVision.GetVisibleFor(ent)), COLOR_SLATEGRAY)

		local color = COLOR_WHITE

		mvData:AddIcon(greendemonboxMV, (mvData:IsOffScreen() or not mvData:IsOnScreenCenter()) and color)

		mvData:SetCollapsedLine(distance)
	end)
end