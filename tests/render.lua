package.path='./bld/?.lua;./bld/?/init.lua;' .. package.path
package.loaded['tek.ui']={Frame={draw=function() return true end}}
Flags={DispScale=100,screenShift={x=0,y=0},Transformations={
  Scale={x=1,y=1,z=1},Move={x=0,y=0,z=0},Rotate=0,
}}
local draw=require('conf.gui.common.lib.display.draw_draft').draw
local function finite(n) assert(n==n and n~=math.huge and n~=-math.huge) end
local drawable={pushClipRect=function() end,popClipRect=function() end,
  drawLine=function(_,x1,y1,x2,y2) finite(x1);finite(y1);finite(x2);finite(y2) end}
for _,projection in ipairs{'xy','xyz'} do
  Flags.DisplayProection=projection
  for _,point in ipairs{{x=0,y=0,z=0},{x=10,y=0,z=0},{x=0,y=10,z=0},{x=0,y=0,z=10}} do
    for _,empty in ipairs{true,false} do
      local points={[0]={x=0,y=0,z=0}}
      if not empty then points[1]=point end
      local view={Window={Drawable=drawable}, Points=points, PenWalk=1,
        Bnd={xmin=0,ymin=0,zmin=0,xmax=point.x,ymax=point.y,zmax=point.z},
        sel_line={i=99},getRect=function() return 0,0,300,300 end,
        drawAxis=function() end,drawWritings=function() end,drawZeroCross=function() end}
      assert(draw(view))
      finite(view.k);finite(view.dx);finite(view.dy)
      if projection=='xyz' then finite(view.k3d) end
      assert(view.sel_line==nil)
    end
  end
end
print('empty and single-axis rendering tests passed')
