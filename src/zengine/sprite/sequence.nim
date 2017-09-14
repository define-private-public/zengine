# frame/sequence.nim
#
# Sequnce is an ordered collection of `TimedFrame` objects.  It defines a
# sequence of animation.
from math import fmod
from tables import Table, initTable, contains, len, `[]`, `[]=`
import strfmt
import frame


# A collection of frames in order
type Sequence* = ref object
  name*: string             # Name of the Sequence
  frames*: seq[TimedFrame]  # Frames that makeup the sequence
  looping*: bool            # Does the sequence loop?
  duration: float           # Cache of the total duration of the sequence


# String representation of a TimedFrame
proc `$`*(self: Sequence): string=
  var s = "Sequence[{0}".fmt(self.name)
  if self.looping:
    s &= ", looping"
  s &= "] "

  for tf in self.frames:
    s &= "{0}:{1}, ".fmt(tf.frame.name, tf.hold)
  s = s[0..(s.len() - 3)]

  return s



# ================== #
# Sequence Accessors #
# ================== #

# Report the length (as in time) of the squence in seconds
proc duration*(self: Sequence): float {.inline.}=
#  let holds = map(self.frames, proc(x: TimedFrame): float= x.hold)
#  return foldl(holds, a + b)
  return self.duration


# Returns the frame at the supplied index.  Throws an error of the index is out
# of range.
proc atIndex*(self: Sequence; i: int): TimedFrame {.inline.}=
  return self.frames[i]


# Returns the frame at the time (in floats)
#
# If `looping=false`, then this will clamp the boundaires.  Either returning the
# first frame or the last frame.  If `looping=true` then this will return the
# Frame at the looped time (which could be any frame).
#
# This could cause some sort of problem if there are no frames in the sequence
# but something trimes to be accessed.
proc atTime*(self: Sequence; time: float): TimedFrame=
  var loopedTime: float
  if self.looping:
    # Get a modulo'd time
    loopedTime = fmod(time, self.duration)
  else:
    # bounds possiblity
    if time < 0:
      return self.frames[0]
    elif (time >= self.duration):
      return self.frames[self.frames.len() - 1]

  # Iterate and count the time
  var t = 0.0
  for tf in self.frames:
    t += tf.hold
    if loopedTime < t:
      return tf



# ================= #
# Sequence Mutators # 
# ================= #

# Add a frame to the sequence with a supplied hold value (in seconds)
proc add*(self: Sequence; frame: Frame; hold: float) {.inline.}=
  self.frames.add(TimedFrame(frame: frame, hold: hold))
  self.duration += hold

