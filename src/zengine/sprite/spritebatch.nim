# Spritebatch is used for rendering a lot of sprites.  This is where all of the OpenGL logic for the sprites live.

from tables import values
import strfmt
import glm
import ../zgl
from ../texture import drawTexture, drawTextureRec
from ../geom import Rectangle
from ../color import WHITE
import sprite

# TODO allow for custom OpenGL (i.e. custom rendering batches


type
  SpriteBatch* = ref object of RootObj
    # TODO make into a sprite
    renderQueue: seq[Sprite]         # Order to render objects in, TODO initial size?  (it's a nice optimization)

  
proc initSpriteBatch*(): SpriteBatch=
  return SpriteBatch(
    renderQueue: @[]
  )


# Adds sprite to the render queue
# TODO pointer to sprite?  Shouldn't have to copy any data
proc add*(self: SpriteBatch; spr: Sprite) {.inline.}=
  self.renderQueue.add(spr)


# Clears out the rendering queue
proc clear*(self: SpriteBatch) {.inline.}=
  self.renderQueue.setLen(0)    #  Clear, but keep alocated size


# TODO updateAll proc?

# Draws all of the sprites in the batch
proc drawAll*(self: SpriteBatch)=
  # TODO scale?
  # TODO rotate?
  for spr in self.renderQueue:
    spr.draw()
#    var
#      x = 0
#      y = 0
#    for frame in spr.frames.values():
#      drawTextureRec(spr.spritesheet, frame.rect, vec2f(x.float, y.float), WHITE)
#      x += frame.rect.width
#      y += frame.rect.height
#    drawTextureRec(spr.spritesheet,
#                    Rectangle(x: 0, y: 0, width: spr.spritesheet.width(), height: spr.spritesheet.height()),
#                    vec2f(0.0, 0.0), WHITE)


