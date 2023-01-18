hook.Add("CalcMainActivity", "AOTCannon:CalcActivity", function (ply, vel)
    local seat = ply:GetVehicle()
    if not IsValid(seat) then return end
    local par = seat:GetParent()
    if not IsValid(par) then return end
    if par:GetClass() != "joes_aot_cannon" then return end

    local return1 = ACT_IDLE
    local return2 = ply:LookupSequence("idle_all_angry")

    return return1,return2
end)

hook.Add("CalcView", "AOTCannon:CalcView", function (ply, pos, angles, fov)
    local seat = LocalPlayer():GetVehicle()
    if not IsValid(seat) then return end
    local par = seat:GetParent()
    if not IsValid(par) then return end
    if par:GetClass() != "joes_aot_cannon" then return end

    local view = {
        origin = pos + Vector(0,0,68),
        angles = angles,
        fov = fov,
        drawviewer = true
    }

    //view.origin = par:LocalToWorld(Vector(-20,50,80))
    //view.angles:RotateAroundAxis(view.angles:Right(), 180)
    //view.angles:RotateAroundAxis(view.angles:Up(), 0)
    //view.angles:RotateAroundAxis(view.angles:Forward(), 180)
    //view.angles.p = -view.angles.p
    return view
end)
