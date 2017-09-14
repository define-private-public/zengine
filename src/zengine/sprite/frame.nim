# sprite/frame.nim
#
# Contains two types: `Frame` and `TimedFrame`.  The former is used to define a
# rectangle (w/ origin point) over a spritesheet, which is a frame of animation.
# The latter points to a `Frame` but also contains a timing value.
import glm, strfmt
from ../geom import Rectangle



# Section from the spritesheet to show
type Frame* = ref object
  name*: string       # Name of the Frame
  rect*: Rectangle    # sub-section of the spritesheet that is one frame
  origin*: Vec2f      # center (relative to the `rect`) of the Frame,  default is (0, 0)


# String representation of a Frame
proc `$`*(self: Frame): string=
  var s = "Frame[{0}] r={1}".fmt(self.name, $self.rect)
  if (self.origin.x) != 0 or (self.origin.y != 0):
    s &= " o=({0}, {1})".fmt(self.origin.x, self.origin.y)

  return s



# A Frame with a timing value
#
# It's best not to create these directly.  Use the `add()` proc on the
# `Sequence` type to do that.
type TimedFrame* = ref object
  frame*: Frame       # Frame that should be shown
  hold*: float        # How long to hold the frame out for (in seconds), should be positive


# String representation of a TimedFrame
proc `$`*(self: TimedFrame): string=
  return "TimedFrame[{0}] h={1}".fmt(self.frame.name, self.hold)
