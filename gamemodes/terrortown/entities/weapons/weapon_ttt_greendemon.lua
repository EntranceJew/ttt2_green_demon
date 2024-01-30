
if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/weapon_ttt_greendemon.png")
end

if CLIENT then
	SWEP.PrintName = "greendemon_name"
	SWEP.Slot = 6

	SWEP.ViewModelFOV = 90

	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "greendemon_name",
		desc = "greendemon_desc",
	};

	SWEP.Icon = "vgui/ttt/weapon_ttt_greendemon.png"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel          = "models/entities/entities/sent_greendemon_box/box.mdl"
SWEP.WorldModel         = "models/entities/entities/sent_greendemon_box/box.mdl" --tochange

SWEP.HoldType = "grenade"

SWEP.DrawCrosshair      = false
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Delay = 1.0

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true
SWEP.WeaponID = AMMO_CUBE

SWEP.AllowDrop = false
SWEP.NoSights = true


SWEP.ThrowForce = 400
SWEP.ThrowFromDistance = 36

if SERVER then
	local flags = {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	CreateConVar("sv_ttt2_greendemon_use_music", "1", flags) --✔
	CreateConVar("sv_ttt2_greendemon_spawn_delay", "3", flags) --✔
	CreateConVar("sv_ttt2_greendemon_active_range", "1000", flags) --✔
	CreateConVar("sv_ttt2_greendemon_kill_range", "1000", flags) --✔
	CreateConVar("sv_ttt2_greendemon_full_speed_time", "18", flags) --✔
	CreateConVar("sv_ttt2_greendemon_move_speed", "30", flags) --✔
	CreateConVar("sv_ttt2_greendemon_box_throw_force", "400", flags) --✔
	CreateConVar("sv_ttt2_greendemon_prefer_activator_bias", "0.3", flags) --✔
	--@TODO: reset speed if lost all targets

	util.AddNetworkString("TTT2_GreenDemonWarning")
end

if CLIENT then
	net.Receive("TTT2_GreenDemonWarning", function()
		local idx = net.ReadUInt(16)
		local armed = net.ReadBool()

		if armed then
			local pos = net.ReadVector()
			local team = net.ReadString()
			RADAR.bombs[idx] = {pos=pos, nick="Green Demon", team = team}
		else
			RADAR.bombs[idx] = nil
		end

		RADAR.bombs_count = table.Count(RADAR.bombs)
	end)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:MineDrop()
end
function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self:MineDrop()
end

local throwsound = Sound( "Weapon_SLAM.SatchelThrow" )
function SWEP:MineDrop()
	if SERVER then
		local ply = self:GetOwner()
		if not IsValid(ply) then return end

		if self.Planted then return end

		local vsrc = ply:GetShootPos()
		local vang = ply:GetAimVector()
		local moveit = vsrc + (vang * self.ThrowFromDistance)
		local vvel = ply:GetVelocity()

		local vthrow = vvel + (vang * self.ThrowForce)

		local mine = ents.Create("sent_greendemon_box")
		if IsValid(mine) then
			mine:SetPos(moveit)
			mine:Spawn()

			mine:SetOwner(ply)
			mine.WeaponConnection = self

			mine:PhysWake()
			local phys = mine:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(vthrow)
			end

			self:TakePrimaryAmmo(1)

			if self:Clip1() <= 0 then
				 self:Remove()
			end

			-- self.Planted = true
		end
	end

	self:EmitSound(throwsound)
end


function SWEP:Reload()
	return false
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
		RunConsoleCommand("lastinv")
	end
end

if CLIENT then
	function SWEP:Initialize()
		self:AddTTT2HUDHelp("greendemon_help_primary")
		return self.BaseClass.Initialize(self)
	end

	function SWEP:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_equipment_additional")

		form:MakeHelp({
			label = "desc_ttt2_greendemon_use_music"
		})
		form:MakeCheckBox({
			serverConvar = "sv_ttt2_greendemon_use_music",
			label = "label_ttt2_greendemon_use_music",
		})

		form:MakeHelp({
			label = "desc_ttt2_greendemon_spawn_delay"
		})
		form:MakeSlider({
			serverConvar = "sv_ttt2_greendemon_spawn_delay",
			label = "label_ttt2_greendemon_spawn_delay",
			min = 0,
			max = 6,
			decimal = 2,
		})

		form:MakeHelp({
			label = "desc_ttt2_greendemon_active_range"
		})
		form:MakeSlider({
			serverConvar = "sv_ttt2_greendemon_active_range",
			label = "label_ttt2_greendemon_active_range",
			min = 0,
			max = 10000,
			decimal = 0,
		})

		form:MakeHelp({
			label = "desc_ttt2_greendemon_kill_range"
		})
		form:MakeSlider({
			serverConvar = "sv_ttt2_greendemon_kill_range",
			label = "label_ttt2_greendemon_kill_range",
			min = 0,
			max = 2000,
			decimal = 0,
		})

		form:MakeHelp({
			label = "desc_ttt2_greendemon_full_speed_time"
		})
		form:MakeSlider({
			serverConvar = "sv_ttt2_greendemon_full_speed_time",
			label = "label_ttt2_greendemon_full_speed_time",
			min = 0,
			max = 60,
			decimal = 0,
		})

		form:MakeHelp({
			label = "desc_ttt2_greendemon_move_speed"
		})
		form:MakeSlider({
			serverConvar = "sv_ttt2_greendemon_move_speed",
			label = "label_ttt2_greendemon_move_speed",
			min = 0,
			max = 200,
			decimal = 0,
		})

		form:MakeHelp({
			label = "desc_ttt2_greendemon_box_throw_force"
		})
		form:MakeSlider({
			serverConvar = "sv_ttt2_greendemon_box_throw_force",
			label = "label_ttt2_greendemon_box_throw_force",
			min = 0,
			max = 4000,
			decimal = 0,
		})

		form:MakeHelp({
			label = "desc_ttt2_greendemon_prefer_activator_bias"
		})
		form:MakeSlider({
			serverConvar = "sv_ttt2_greendemon_prefer_activator_bias",
			label = "label_ttt2_greendemon_prefer_activator_bias",
			min = 0,
			max = 1,
			decimal = 2,
		})
	end
end

function SWEP:Deploy()
	if SERVER and IsValid(self:GetOwner()) then
		self:GetOwner():DrawViewModel(false)
	end
	return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end

