module("luci.controller.k3screenctrl", package.seeall)

function index()
  if not nixio.fs.access("/etc/config/k3screenctrl") then
    return
  end
  entry({"admin","services","k3screenctrl"}, cbi("k3screenctrl"), _("Screen"), 10).dependent = true
end