AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/aot_model/cannon.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	
	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then 
		self:Remove()
		return
	end
	
	phys:Wake()

end


function ENT:Think()
	self:NextThink(CurTime())
	return true
end