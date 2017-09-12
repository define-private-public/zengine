import strfmt
import glm

type
  Rectangle* = object
    x*, y*, width*, height*: int


proc `$`*(self: Rectangle): string {.inline.}=
  return "Rectangle(x={0}, y={1}, width={2}, height={3})".fmt(self.x, self.y, self.width, self.height)


## Check to see if a point is within a rectangle (inclusive)
proc contains*(r: Rectangle; p: Vec2f): bool {.inline.}=
  return p.x >= r.x.float and
         p.y >= r.y.float and
         p.x <= (r.x + r.width).float and
         p.y <= (r.y + r.height).float
