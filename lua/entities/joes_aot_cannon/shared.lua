ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "AOT Cannon"
ENT.Category = "Joe | AOT"

ENT.Spawnable = true
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "Barrel" )
end