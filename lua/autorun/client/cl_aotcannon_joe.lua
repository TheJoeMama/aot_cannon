hook.Add("CalcMainActivity", "AOTCannon:CalcActivity", function (ply, vel)
    if ply != LocalPlayer() then return end
    local seat = ply:GetVehicle()
    if not IsValid(seat) then return end
    local par = seat:GetParent()
    if not IsValid(par) then return end
    if par:GetClass() != "joes_aot_cannon" then return end

    local return1 = ACT_IDLE
    local return2 = ply:LookupSequence("idle_dual")

    return return1,return2
end)

hook.Add("CalcView", "AOTCannon:CalcView", function (ply, pos, angles, fov)
    local seat = LocalPlayer():GetVehicle()
    if not IsValid(seat) then return end
    local par = seat:GetParent()
    if not IsValid(par) then return end
    if par:GetClass() != "joes_aot_cannon" then return end

    local vehicle = seat
    local _, ang, _ = vehicle:GetVehicleViewPosition()
    ang = par:GetAngles()
    local seatOffset = vehicle:GetAttachment(vehicle:LookupAttachment("vehicle_driver_eyes")).Ang
    //seatOffset = -par:GetAngles()
    local _, turnAng = WorldToLocal(vector_origin, ang, vector_origin, seatOffset)

    local view = {
        origin = par:LocalToWorld(Vector(200,50,80)),
        angles = angles,
        fov = fov,
        drawviewer = true
    }

    seatOffset:RotateAroundAxis(seatOffset:Up(),190)
    //view.angles = seatOffset
    return view
end)
