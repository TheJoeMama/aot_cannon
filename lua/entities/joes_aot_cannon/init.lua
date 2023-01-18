AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
    local ent = ents.Create( ClassName )
    ent:SetPos( tr.HitPos + tr.HitNormal )
	local ang = ply:EyeAngles()
	ang:RotateAroundAxis(ang:Right(), 180)
	ang.p = 0
	ang.r = 0
	ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
	ent:GetPhysicsObject():EnableMotion(false)
	
    return ent
end

function ENT:Initialize()
	self:SetModel("models/aot_model/base.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	self:AddFlags( FL_OBJECT )

	self.debug = false
	self.seat = nil
	self.curtilt = 0
	self.nextattack = 0
	self.nextmove = 0
	self.firing = false
	
	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then 
		self:Remove()
		return
	end
	
	phys:Wake()

	timer.Simple(0.1, function()
		if not IsValid(self) then return end
		self:SpawnCannon()
		self:SpawnSeat()
	end)
end

function ENT:SpawnSeat()
	self.seat = ents.Create("prop_vehicle_prisoner_pod")
	self.seat:SetModel("models/props_c17/FurnitureCouch001a.mdl") // avoid exit sequence
	self.seat:SetPos(self:LocalToWorld(Vector(-15,55,8)))
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(),-90)
	self.seat:SetAngles(ang)
	self.seat:SetKeyValue("vehiclescript","scripts/vehicles/prisoner_pod.txt")
	self.seat:SetKeyValue("limitview", 0)
	self.seat:Spawn()
	self.seat:Activate()
	self.seat:SetParent(self)
	self.seat:DrawShadow(false)
	self.seat:SetNoDraw(true)
	self.seat:SetNotSolid(true)
	self.seat:SetCollisionGroup(COLLISION_GROUP_WORLD)

end

function ENT:SetBarrelTilt(newtilt)
	newtilt = math.Clamp(newtilt, -54, 3)
	self.curtilt = newtilt
	local curang = self.BARREL:GetAngles()
	local ang = Angle(newtilt,curang.y,curang.r)
	self.BARREL:SetAngles(ang)
	local originalpos = self:LocalToWorld(Vector(0,0,1.5))
	local curpos = self.BARREL:GetPos()
	local posnewtilt = math.abs(newtilt)
	local newheight = posnewtilt / 6
	if newtilt < -30 then
		newheight = posnewtilt * 0.16
	elseif newtilt > 0 then
		newheight = posnewtilt * -0.1
	end
	self.BARREL:SetLocalPos(Vector(0,0,newheight + 1.5))
end

function ENT:SpawnCannon()
	self.BARREL = ents.Create("joes_aot_barrel")
	self.BARREL:SetModel("models/aot_model/cannon.mdl")
	self.BARREL:SetPos(self:LocalToWorld(Vector(0,0,1.5)))
	self.BARREL:SetAngles(self:GetAngles())
	self.BARREL:Spawn()
	self.BARREL:SetParent(self)
	local phys = self.BARREL:GetPhysicsObject()
	phys:EnableMotion(false)
	phys:Wake()
	self.BARREL:SetPlaybackRate(1)
	
	self:SetBarrel(self.BARREL)
end

function ENT:Reload()
	self.nextattack = CurTime() + 2
end

function ENT:OnRemove()
	if IsValid(self.BARREL) then
		SafeRemoveEntity(self.BARREL)
	end
	if IsValid(self.seat) then
		if IsValid(self.seat:GetDriver()) then self.seat:GetDriver():ExitVehicle() end
		SafeRemoveEntity(self.seat)
	end
end

function ENT:FireShell()
	self.firing = true
	timer.Simple(0, function()
		if not IsValid(self) or not IsValid(self.BARREL) then return end
		local effectang = self.BARREL:GetAngles()
		effectang:RotateAroundAxis(effectang:Right(), 90)
		ParticleEffect("zay_shot", self.BARREL:LocalToWorld(Vector(-90,0,62)), effectang, self)

		self:EmitSound("aot/joe_canon5.wav",100,100,1,CHAN_AUTO,32)
	end)
	timer.Simple(0.1, function()
		if not IsValid(self) or not IsValid(self.BARREL) then return end
		self.BARREL:ResetSequence(self.BARREL:LookupSequence("shoot"))
		util.ScreenShake(self:GetPos(), 10, 50, 0.6, 600)
	end)	

	local ent = ents.Create("joe_shell")
	ent:SetPos(self.BARREL:LocalToWorld(Vector(-15,0,60)))
	local ang = self.BARREL:GetAngles()
	ang:RotateAroundAxis(ang:Right(), 90)
	ent:SetAngles(ang)
	ent:Spawn()
	ent:DrawShadow(false)
	ent.player = self.seat:GetDriver()

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:EnableMotion(true)
		phys:SetMass(5000)

		local tickrate = 66.6 * engine.TickInterval()
		local force = 5000 - math.Clamp(4000 * ( self.curtilt / -45),0,4500)
		force = force * tickrate


		phys:ApplyForceCenter((ent:GetUp() * phys:GetMass()) * force)
		phys:ApplyTorqueCenter( (ang:Right()  * phys:GetMass()) * 1 )
	end

	self.firing = false
	self.nextmove = CurTime() + self.BARREL:SequenceDuration(self.BARREL:LookupSequence("shoot"))
	self:Reload()
end

function ENT:Use(ply)
	local driver = self.seat:GetDriver()
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if ply == driver then
		ply:ExitVehicle()
	elseif not IsValid(driver) then
		local result = hook.Run("AOTCANNON_CanUserEnterArtillery", self, ply)
		if result == false then return end

		if IsValid(self.seat) then
			ply:EnterVehicle(self.seat)
			timer.Simple(0, function()
				if not IsValid( ply ) or not IsValid( self ) then return end
				local Ang = Angle(0,-90,0)
		
				/*
				Ang = self:GetAngles()
				Ang:RotateAroundAxis(Ang:Right(), 180)
				//Ang = (ply:GetPos() - self.BARREL:LocalToWorld(Vector(-50,40,20))):Angle()
				Ang.r = 0
				//Ang:RotateAroundAxis(Ang:Right(), 180)
				//Ang:RotateAroundAxis(Ang:Up(), 0)
				//Ang:RotateAroundAxis(Ang:Forward(), 180)
				//Ang.p = -Ang.p
				*/

				ply:SetEyeAngles( Ang )
			end)
		else 
			self:SpawnSeat()
		end
	end
end

function ENT:Think()
	local curang = self:GetAngles()
	local newang = curang
	local newtilt = self.curtilt

	local driver = self.seat:GetDriver()
	if self.debug and not IsValid(driver) then
		driver = Entity(1)
	end

	if IsValid(driver) then
		if self.nextmove < CurTime() and self.firing == false then
			if driver:KeyDown(IN_MOVERIGHT) then
				newang = LerpAngle(0.5,newang,newang - Angle(0,1,0))
			end
			if driver:KeyDown(IN_MOVELEFT) then
				newang = LerpAngle(0.5,newang,newang + Angle(0,1,0))
			end

			if driver:KeyDown(IN_FORWARD) then
				newtilt = Lerp(0.5,newtilt,newtilt - 1)
			end
			if driver:KeyDown(IN_BACK) then
				newtilt = Lerp(0.5,newtilt,newtilt + 1)
			end

			self:SetAngles(newang)
			self:SetBarrelTilt(newtilt)
		end

		if ( driver:KeyDown(IN_ATTACK) or self.debug ) and self.firing == false and self.nextattack < CurTime() then
			local result = hook.Run("AOTCANNON_CanUserFireArtillery", self, driver)
			if result == false then return end
			self:FireShell()
		end
	end

	self:NextThink(CurTime())
	return true
end