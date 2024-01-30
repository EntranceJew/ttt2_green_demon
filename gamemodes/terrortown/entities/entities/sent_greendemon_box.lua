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

function ENT:SendWarn(armed)
	-- if (!armed or (IsValid(ent:GetOwner()) and enti.Owner:IsRole(ROLE_TRAITOR))) then
	net.Start("TTT2_GreenDemonWarning")
	net.WriteUInt(self:EntIndex(), 16)
	net.WriteBool(armed)
	--net.WriteBit(armed)
	net.WriteVector(self:GetPos())
	net.WriteString(self:GetOwner():GetTeam())
	--net.Send(GetTraitorFilter(true))
	net.Broadcast()
	-- end
end

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
	end

---@diagnostic disable-next-line: undefined-field
	return self.BaseClass.Initialize(self)
end

if SERVER then
	function ENT:Think()
		if (not self.Solidified and CurTime() > (self.SpawnTime + self.ArmTime)) then
			self:SetCollisionGroup(COLLISION_GROUP_NONE)
			self.Solidified = true
			self:SendWarn(true)
		end
	end
end

function ENT:SpawnDemon(ply)
	local ent = ents.Create("sent_greendemon")
	if not IsValid(ent) then return end
	ent.activator = ply
	local ep = ply:EyePos() - ply:GetPos()
	ent:SetPos(self:GetPos() + ep)
	ent:Spawn()

	local owner = self:GetOwner()
	ent:SetOwner(owner)
	ent:SetPhysicsAttacker(owner --[[@as Player]])
	ent.WeaponConnection = self.WeaponConnection

	self:SendWarn(false)
	self:Remove()
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