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
	print(ent)
	
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
	
	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then 
		self:Remove()
		return
	end
	
	phys:Wake()

	timer.Simple(0.1, function()
		if not IsValid(self) then return end
		self:SpawnCannon()
	end)
end

function ENT:SetBarrelTilt(newtilt)
	newtilt = math.Clamp(newtilt, -54, 0)
	local curang = self.BARREL:GetAngles()
	local ang = Angle(newtilt,curang.y,curang.r)
	self.BARREL:SetAngles(ang)
	local originalpos = self:LocalToWorld(Vector(0,0,1.5))
	local curpos = self.BARREL:GetPos()
	newtilt = -newtilt
	local newheight = newtilt / 6
	if newtilt > 30 then
		newheight = newtilt * 0.16
	end
	self.BARREL:SetPos(originalpos + Vector(0,0,newheight))
end

function ENT:SpawnCannon()
	self.BARREL = ents.Create("prop_physics")
	self.BARREL:SetModel("models/aot_model/cannon.mdl")
	self.BARREL:SetPos(self:LocalToWorld(Vector(0,0,1.5)))
	self.BARREL:SetAngles(self:GetAngles())
	self.BARREL:Spawn()
	local phys = self.BARREL:GetPhysicsObject()
	phys:EnableMotion(false)
	phys:Wake()

end

function ENT:OnRemove()
	if IsValid(self.BARREL) then
		SafeRemoveEntity(self.BARREL)
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
	self.way = self.way or false
	self.nexttilt = self.nexttilt or 1
	if not self.way then
		self.nexttilt = self.nexttilt - 1
	elseif self.way then
		self.nexttilt = self.nexttilt + 1
	end
	if not self.way and self.nexttilt < -54 then
		self.way = true
		self.nexttilt = -54
	elseif self.way and self.nexttilt > 0 then
		self.nexttilt = 0
		self.way = false
	end
	self:SetBarrelTilt(self.nexttilt)
	self:NextThink(CurTime() + 0.01)
	return true
end