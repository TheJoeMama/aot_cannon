include("shared.lua")

function ENT:Initialize()
	timer.Simple(0,function()
		if IsValid(self) then
			zay.f.ParticleEffectAttach("zay_shell_trail", self, 0)
		end
	end)
end

function ENT:DrawTranslucent()
	self:Draw()
end

function ENT:Draw()
	self:DrawModel()
end
