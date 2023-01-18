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

	self.debug = true
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
	self.seat:SetModel("models/props_interiors/Furniture_Lamp01a.mdl")
	self.seat:SetPos(self:LocalToWorld(Vector(15,60,0)))
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
	self.BARREL = ents.Create("prop_physics")
	self.BARREL:SetModel("models/aot_model/cannon.mdl")
	self.BARREL:SetPos(self:LocalToWorld(Vector(0,0,1.5)))
	self.BARREL:SetAngles(self:GetAngles())
	self.BARREL:Spawn()
	self.BARREL:SetParent(self)
	local phys = self.BARREL:GetPhysicsObject()
	phys:EnableMotion(false)
	phys:Wake()
	self.BARREL:SetPlaybackRate(0.1)
	self:SetBarrel(self.BARREL)
end

function ENT:Reload()
	self.nextattack = CurTime() + 2
end

function ENT:OnRemove()
	if IsValid(self.BARREL) then
		SafeRemoveEntity(self.BARREL)
	end
end

function ENT:FireShell()
	self.firing = true
	local effectang = self.BARREL:GetAngles()
	effectang:RotateAroundAxis(effectang:Right(), 90)
	timer.Simple(0, function()
		local effectdata = EffectData()
		effectdata:SetScale(5)
		effectdata:SetOrigin(self.BARREL:LocalToWorld(Vector(-90,0,60)))
		effectdata:SetAngles(effectang)
		//util.Effect("explosion", effectdata)
		ParticleEffect("zay_shot", self.BARREL:LocalToWorld(Vector(-90,0,62)), effectang, self)
	end)
	timer.Simple(0.2, function()
		self.BARREL:ResetSequence("shoot")
		util.ScreenShake(self:GetPos(), 10, 50, 0.6, 600)
	end)	

	self:EmitSound("aot/cannon4.mp3",150,100,1)
	local ent = ents.Create("joe_shell")
	ent:SetPos(self.BARREL:LocalToWorld(Vector(-30,0,60)))
	local ang = self.BARREL:GetAngles()
	ang:RotateAroundAxis(ang:Right(), 90)
	ent:SetAngles(ang)
	//ent:Spawn()

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
	self.nextmove = CurTime() + 0.75
	self:Reload()
end

function ENT:Use(ply)
	if IsValid(ply) and ply:IsPlayer() then
		if IsValid(self.seat) then
			ply:EnterVehicle(self.seat)
			
		else
			self:SpawnSeat()
		end
	end
end

function ENT:Think()
	/*local curpos = self.BARREL:GetPos()
	local originalpos = self:GetPos()
	originalpos.z = curpos.z
	self.BARREL:SetPos(originalpos)
	local curang = self.BARREL:GetAngles()
	local originalang = self:GetAngles()
	originalang.p = curang.p
	self.BARREL:SetAngles(originalang)*/

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
			self:FireShell()
		end
	end

	self:NextThink(CurTime())
	return true
end