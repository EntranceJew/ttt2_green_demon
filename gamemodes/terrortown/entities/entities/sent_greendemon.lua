ENT.Type = "anim"

ENT.PrintName		= "Green Demon"
ENT.Author			= "WasabiThumbs"
ENT.Contact			= "Don't"
ENT.Purpose			= "Give yourself a challenge."
ENT.Instructions	= "Place and run! Targets nearest."
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup     = RENDERGROUP_TRANSLUCENT
ENT.ShadowPosition = Vector(0,0,0)

function ENT:Initialize()
end

ENT.SparkleDecay = 0.5
ENT.SparkleHeightOffset = 12
ENT.ShadowTraceDistance = 9000
ENT.SparkleRadius = 8
--
ENT.SparkleDepth = 8
ENT.SparkleBuffer = {}
ENT.SparkleIndex = 1
ENT.SparkleWait = 0.15
ENT.LastSparkleTime = -math.huge

if CLIENT then
	ENT.Category = "SM64"

	ENT.GreenDemonMat = Material("models/entities/entities/sent_greendemon/gd.png")
	ENT.ShadowMat = Material("models/entities/entities/sent_greendemon/shadowtex.png")
	ENT.SparkMat = Material("models/entities/entities/sent_greendemon/gd_glint")
	ENT.TrailTab = {}

	function ENT:Draw() end

	function ENT:DrawTortuga() --CL
		cam.Start3D()
		-- render.SetMaterial( self.GreenDemonMat )
		-- local hs = 16
		-- render.DrawSprite( self:GetPos(), hs, hs, color_white )

		render.SetMaterial(self.SparkMat)
		for _, sparkle in ipairs(self.SparkleBuffer) do
			render.DrawSprite(sparkle[1], 10, 10, Color(255,255,255,sparkle[2]))
		end
		render.SetMaterial(self.GreenDemonMat)
		render.DrawSprite(self:GetPos() + Vector(0,0,12), 10, 10, color_white)

		render.SetMaterial(self.ShadowMat)
		render.DrawQuadEasy(self.ShadowPosition, Vector(0,0,1), 10, 10, color_white)

		cam.End3D()
	end

	hook.Add( "PostDrawTranslucentRenderables", "GreenDemonPostDraw", function( _, bSkybox )
		if bSkybox then return end
		local newList = {}
		for _,v in ipairs(ents.FindByClass("sent_greendemon")) do
			newList[LocalPlayer():EyePos():DistToSqr(v:GetPos())] = v
		end

		local keysList = table.GetKeys(newList)
		for _,_ in pairs(newList) do
			local thisKey = math.max(unpack(keysList))
			table.RemoveByValue(keysList, thisKey)
			local v = newList[thisKey]
			v:DrawTortuga()
		end
	end )

	function ENT:Think()
		for _, sparkle in ipairs(self.SparkleBuffer) do
			sparkle[2] = sparkle[2] * self.SparkleDecay
		end

		if CurTime() > (self.LastSparkleTime + self.SparkleWait) then
			self.SparkleBuffer[ self.SparkleIndex ] = {self:GetPos() + Vector(0,0,self.SparkleHeightOffset) + (VectorRand() * self.SparkleRadius), 255}
			self.LastSparkleTime = CurTime()
			self.SparkleIndex = self.SparkleIndex % self.SparkleDepth + 1
		end
	end
end

ENT.DeathSound = Sound("entities/entities/sent_greendemon/sm64_1up.wav")
ENT.KillSound  = Sound("entities/entities/sent_greendemon/sm64_mario_hurt_lose_life.wav")
ENT.SpawnSound = Sound("entities/entities/sent_greendemon/sm64_1up_appears.wav")
ENT.ChaseMusic = Sound("entities/entities/sent_greendemon/sm64_metal_cap.wav")

if SERVER then
	AddCSLuaFile()

	ENT.MakeTime = CurTime()
	function ENT:Initialize()
		self:SetModel( "models/props_lab/huladoll.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:DrawShadow(false)
		self.MakeTime = CurTime()

		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:EnableGravity(false)
		end
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

		self:EmitSound(self.SpawnSound)

		self.ActivateTime = self.MakeTime + GetConVar("sv_ttt2_greendemon_spawn_delay"):GetFloat()
	end

	function ENT:Use( activator, caller )
		return
	end
	ENT.DepositFrames = 0
	ENT.CurCoinsSpawned = 0
	ENT.LoopSound = -1

	function ENT:Think()
		local tr = util.TraceLine({
			start = self:GetPos() + Vector(0,0,self.SparkleHeightOffset),
			endpos = self:GetPos() - Vector(0,0,self.ShadowTraceDistance),
			filter = self,
		})
		if tr.Hit then
			self.ShadowPosition = tr.HitPos + Vector(0,0,0.1)
		end

		if !self.Solidified then
			if CurTime() > self.ActivateTime then
				self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				self.Solidified = true
				if GetConVar("sv_ttt2_greendemon_use_music"):GetBool() then
					local rf = RecipientFilter()
					rf:AddAllPlayers()
					self.LoopSound = CreateSound( self, self.ChaseMusic, rf )
					self.LoopSound:Play()
				end
			else
				return
			end
		end

		local nearest = nil
		local nearest_dist = GetConVar("sv_ttt2_greendemon_active_range"):GetInt() or math.huge
		nearest_dist = nearest_dist * nearest_dist
		for _, ply in ipairs(player.GetAll()) do
			if !ply:IsSpec() then
				local dist = ply:EyePos():DistToSqr( self:GetPos() )
				if ply == self.activator then
					dist = dist * math.Clamp(1 - GetConVar("sv_ttt2_greendemon_prefer_activator_bias"):GetFloat(), 0, 1)
				end
				if dist < nearest_dist then
					nearest = ply
					nearest_dist = dist
				end
			end
		end

		if IsValid(nearest) then
			if nearest_dist <= GetConVar("sv_ttt2_greendemon_kill_range"):GetInt() and nearest:Alive() then
				self:KillEm(nearest)
			else
				local normVec = (nearest:EyePos() - self:GetPos()):GetNormalized()
				local phys = self:GetPhysicsObject()
				local scale = (CurTime() - self.ActivateTime)
				scale = math.min(scale, GetConVar("sv_ttt2_greendemon_full_speed_time"):GetFloat())
				if phys then phys:SetVelocityInstantaneous(normVec * scale * GetConVar("sv_ttt2_greendemon_move_speed"):GetFloat()) end
			end
		end
	end

	function ENT:KillEm(v)
		if GetConVar("sv_ttt2_greendemon_use_music"):GetBool() and self.LoopSound then
			self.LoopSound:Stop()
		end
		v:EmitSound(self.KillSound)

		local dmg = DamageInfo()

		dmg:SetDamage(42069)
		dmg:SetAttacker(self:GetOwner())
		dmg:SetDamageForce(v:GetAimVector())
		dmg:SetDamagePosition(v:GetPos())
		dmg:SetDamageType(DMG_CLUB)
		dmg:SetInflictor(self)

		v:TakeDamageInfo(dmg)
		-- v:SetNWBool("sm64_greendemon_mutedefault", true)
		-- local myphys = self:GetPhysicsObject()
		-- if IsValid(myphys) then v:SetAbsVelocity(myphys:GetVelocity()*4) end
		-- timer.Simple(1.3, function()
		-- 	if IsValid(v) then
		-- 		v:SetNWBool("sm64_greendemon_mutedefault", false)
		-- 		v:ScreenFade(SCREENFADE.OUT, Color(0,0,0), 0.85, 0.3)
		-- 		timer.Simple(1.05, function() if IsValid(v) then v:Spawn() end end)
		-- 	end
		-- end )

		self:EmitSound(self.DeathSound)
		self:Remove()
	end

	function ENT:SpawnFunction( ply, tr, ClassName )

		if ( !tr.Hit ) then return end

		local SpawnPos = tr.HitPos

		local ent = ents.Create( ClassName )
		ent:SetPos( SpawnPos )
		ent:Spawn()
		ent:Activate()
		local vec = ( ply:EyePos() - ent:GetPos() ):GetNormalized():Angle();
		ent:SetAngles(vec)

		return ent

	end
end