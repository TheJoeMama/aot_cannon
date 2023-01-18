AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:SpawnFunction(ply, tr)
	local SpawnPos = tr.HitPos + tr.HitNormal * 1
	local ent = ents.Create(self.ClassName)
	ent:SetPos(SpawnPos)
	local angle = ply:GetAimVector():Angle()
	angle = Angle(0, angle.yaw, 0)
	angle:RotateAroundAxis(angle:Up(), 90)
	ent:SetAngles(angle)
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:UseClientSideAnimation()
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(true)
	end

	self.zay_Collided = false
end

function ENT:PhysicsCollide(data, phys)
	if self.zay_Collided == true then return end


	timer.Simple(0, function()
		if not IsValid(self) then return end
		self:SetNoDraw(true)
		local a_phys = self:GetPhysicsObject()

		if IsValid(a_phys) then
			a_phys:Wake()
			a_phys:EnableMotion(false)
		end
	end)

	local selfpos = self:GetPos()
	zay.f.CreateNetEffect("shell_explosion",selfpos) // Zeros Artillery handles Particle Creation

	self.player = IsValid(self.player) and self.player or self
	for k,v in pairs(ents.FindInSphere(selfpos,300)) do
		if IsValid(v) then
			local d = DamageInfo()
			if v:IsPlayer() then
				d:SetDamage( 200 )
			elseif v:IsNPC() then
				d:SetDamage( 1500 )
			else
				d:SetDamage( 500 )
			end
			d:SetAttacker( self.player )
			d:SetDamageType( DMG_BLAST )
			v:TakeDamageInfo( d )
		end
	end


    local deltime = FrameTime() * 2
    if not game.SinglePlayer() then deltime = FrameTime() * 6 end
    SafeRemoveEntityDelayed(self,deltime)

	self.zay_Collided = true
end
