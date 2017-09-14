from strutils import find, strip, isNilOrEmpty, splitWhitespace, split, join, parseInt
from sequtils import map, foldl
from ospaths import parentDir, joinPath
from tables import Table, initTable, contains, len, `[]`, `[]=`
import strfmt
import glm
from geom import Rectangle, contains, `$`
from zgl import Texture2D, width, height
from texture import loadTexture, drawTexture, drawTextureRec
from color import WHITE
from zobject import getNextID
from entity3d import Entity3D
import sprite/frame
import sprite/sequence
    

# TODO remove Console Logger imports
import logging as log
log.addHandler(newConsoleLogger())


# TODO base methods for `Sprite`
# TODO split `Frame`, `TimeFramed`, `Sequence`, `Sprite`, and `ZSprite` into separate files in a sub folder
# TODO show default frame


# ================ #
# Helper Functions #
# ================ #

# Removes comments from a string
proc stripOutComments(s: string): string=
  let loc = s.find('#')
  if loc == -1:
    return s
  else:
    return s[0..(loc-1)]


# Removes all whitespace from a string
proc removeWhitespace(s: string): string {.inline.}=
  return splitWhitespace(s).join()




# The actual sprite object
type Sprite* = ref object of Entity3D
  visability*: float    # [0.0, 1.0], visability of the frame
  scale*: Vec3f         # Scale
  # TODO non-center orientation origin


# ============== #
# Sprite Methods #
# ============== #

# Update the sprite's logic. `dt` is the change in time (in seconds) since the
# last logical update.  E.g. if we're logically updating at 100 FPS, then `0.01`
# is what should be passed into this.  (NOTE: You're game probably isn't going
# to be at 100 logical FPS.  It's probably going to flucuate all the time.  This
# is meant to be an "as if," examle).
method update*(self: Sprite; dt: float) {.base.}=
  raise newException(Exception, "Sprite.update() should not be directly called.")


# Draw the sprite.  Will call the underlying OpenGL methods to draw the sprite
# to the screen
method draw*(self: Sprite) {.base.}=
  raise newException(Exception, "Sprite.draw() should not be directly called.")



type
  ZSprite* = ref object of Sprite
    spritesheet: Texture2D              # Spritesheet
    frames: Table[string, Frame]        # hash of the frames (Frame.name -> Frame)
    sequences: Table[string, Sequence]  # hash of the sequences (Sequence.name -> Sequence)
    defaultFrameName*: string           # Name of the default frame

    # Playback state
    isPlaying: bool                     # Is the sprite playing a sequence?
    isPaused: bool                      # Have we paused playback?
    playbackTime: float                 # playback time (in seconds)
    curFrame: Frame                     # Current frame which is displayed
    curSequence: Sequence               # Which sequence is being played back
    prevDrawnFrame: Frame               # TODO doc


  # For parsing state
  ZSpriteParsingState = enum
    None                    # Have not started, or done anything
    FindingVersionNumber    # Looking for the verison number
    FindingSpriteSheet      # Looking for the spritesheet
    FindingInfoBlocks       # Looking for a "frame_info" or "sequence_info" block
    ReadingFrameInfo        # Going through the specified frames
    ReadingSequenceInfo     # Going through the sequence info
    Done                    # Successfully read through the sprite


  # List of accepted ZSprite versions
  ValidVersions* {.pure.} = enum
    None                    # Null version no.
    V10 = "v1.0"            # v1.0


  # Errors to use for ZSprite parsing
  InvalidSectionError* = object of ValueError
  NonUniqueNameError* = object of ValueError
  InvalidEffectError* = object of ValueError
  ZSpriteLoadError* = object of ValueError


# ================= #
# ZSprite Accessors #
# ================= #
proc spritesheet*(self: ZSprite): Texture2D {.inline.}=
  return self.spritesheet

proc frames*(self: ZSprite): Table[string, Frame] {.inline.}=
  return self.frames

proc sequences*(self: ZSprite): Table[string, Sequence] {.inline.}=
  return self.sequences



# =============== #
# ZSprite Methods #
# =============== #

## Show a specific named frame of the animated sprite.  This will stop
## playing the sprite if it's already playing a sequence.  If `frameName` is not
## found then nothing will happen.
proc show*(self: ZSprite; frameName: string)=
  if not (frameName in self.frames):
    # Frame needs to be there
    return
  elif not self.isPlaying and (self.curFrame.name == frameName):  # TODO is the not placement correct?
    # If we are not playing, make sure that we aren't already showing it
    return

  # Swith state
  self.isPlaying = false
  self.isPaused = false
  self.playbackTime = 0
  self.curSequence = nil
  self.curFrame = self.frames[frameName]

  # TODO fix origin
  # TODO fix rotation origin


# Will play the squence from the specified starting point (in seconds).
#
# If something else is already playing then this will chance the playback state.
#
# if `seqName` is not found then nothing will change.
proc play*(self: ZSprite; seqName: string; startFrom: float=0.0)=
  # Check for the sequence name
  if not (seqName in self.sequences):
    return

  # Reset the playback state
  self.isPlaying = true
  self.isPaused = false
  self.playbackTime = startFrom
  self.curSequence = self.sequences[seqName]
  self.curFrame = self.curSequence.atTime(startFrom).frame

  # TODO fix origin
  # TODO fix rotation origin


# Paused sprite playback.  this function has no effect if playback is happening
# or if it's already paused
proc pause*(self: ZSprite) {.inline.}=
  if self.isPlaying:
    self.isPaused = true


# Resumes the sprite playback.  This function has no effect if playback is not
# happening, or if it's not paused already.
proc resume*(self: ZSprite) {.inline.}=
  if self.isPlaying:
    self.isPaused = false


# This is a method meant to be called in a _logic_ update loop.  `dt` is the
# amount of time (in seconds) that has passed since the last logical update.
# this funciton will update the animation logic of the ZSprite.
#
# If the sprite is paused, then this function will do nothing.
method update*(self: ZSprite; dt: float)=
  # Do nothing if there is a static frame, or if we're playing yet paused
  if not self.isPlaying or self.isPaused:
    return

  let dur = self.curSequence.duration

  self.playbackTime += dt
  if self.playbackTime >= dur:
    if self.curSequence.looping:
      # Put playback time in the range
      self.playbackTime = fmod(self.playbackTime, dur)
    else:
      # Add to the playback time
      self.playbackTime = dur

  # Pick out a frame
  self.curFrame = self.curSequence.atTime(self.playbackTime).frame

  # TODO fix origin
  # TODO fix rotation origion


# Will draw the sprite.  Either a static frame or what is currently playing.
method draw*(self: ZSprite)=
  # Don't draw hidden sprites
  if self.visability <= 0:
    return

  # TODO matrix stuff for locaion, rotate, scale, origin, etc.
  # TODO 3D texture drawing?
  drawTextureRec(self.spritesheet, self.curFrame.rect, self.pos.xy, WHITE)




# TODO document, what kind of errors this can raise?
proc loadZSprite*(zspriteFilename: string): ZSprite =
  # Tokens for parsing
  const
    FrameInfoToken = "frame_info:"
    SequenceInfoToken = "sequence_info:"
    LoopingToken = "looping"

  # Set the initial structure
  var sprite = ZSprite(
    id: getNextID(),
    visability: 1.0,
    scale: vec3f(1, 1, 1),
    frames: initTable[string, Frame](),
    sequences: initTable[string, Sequence](),
    isPlaying: false,
    isPaused: false,
    playbackTime: 0,
    curFrame: nil,
    curSequence: nil,
    prevDrawnFrame: nil
  )

  # Vars for parsing
  var
    zspriteFile: File
    line = ""
    lineCount = 0
    state: ZSpriteParsingState = None
    version: ValidVersions 

  # Start reading through the file
  zspritefile = zspriteFilename.open()
  state = FindingVersionNumber

  # Go line by line
  while zspriteFile.readline(line):
    lineCount += 1
    let cl = strip(stripOutComments(line))    # cleaned line

#    # Print the line
#    log.info("{0}: {1}".fmt(lineCount, line))

    # Skip empty lines
    if cl.isNilOrEmpty():
      continue

    # Reading is a bit of a state machine process
    case state:
      # Look for a valid version number
      of FindingVersionNumber:
        if cl == $ValidVersions.V10:
          version = ValidVersions.V10
          log.info("Detected {0} ZSprite in `{1}`".fmt($version, zspriteFilename))

          # Move to the next state
          state = FindingSpriteSheet

      # Look for the spriteshet (it's relative to the .zsprite file)
      of FindingSpriteSheet:
        let
          spriteDir = parentDir(zspriteFilename)
          spritesheetPath = joinPath(spriteDir, cl)

        # Print where the sheet is located at
        log.info("Spritesheet is at: " & spritesheetPath)
        sprite.spritesheet = loadTexture(spritesheetPath)
        
        # Shift to finding info
        state = FindingInfoBlocks

      # Looking for a frame info (this is a transitionary block)
      of FindingInfoBlocks:
        if cl == FrameInfoToken:
          state = ReadingFrameInfo
        else:
          raise newException(InvalidSectionError, "Expected `frame_info` block, instead got {0}".fmt(cl))

      # Read frame info
      of ReadingFrameInfo:
        # First check for state change
        if cl == FrameInfoToken:
          continue                      # Skip line, we're already reading Frame Info
        elif cl == SequenceInfoToken:
          state = ReadingSequenceInfo   # Move to Sequence Info
          continue

        # Line must be frame info, nab some data
        let
          parts = removeWhitespace(cl).split('=')
          frameName = parts[0]
          frameGeometry = parts[1].split(':')
          loc = frameGeometry[0].split(',')
          size = frameGeometry[1].split(',')

        # Create the frame
        var frame = Frame(
          name: frameName,
          rect: Rectangle(
            x: loc[0].parseInt(),
            y: loc[1].parseInt(),
            width: size[0].parseInt(),
            height: size[1].parseInt()
          ),
          origin: vec2f(0)
        )

        # Non (0, 0) origin?
        if frameGeometry.len() > 2:
          let altOrigin = frameGeometry[2].split(',')
          frame.origin.x = altOrigin[0].parseInt().float
          frame.origin.y = altOrigin[1].parseInt().float

        # Verify the geometry is good
        let geometryGood =
          frame.rect.x >= 0 and
          frame.rect.y >= 0 and
          frame.rect.width <= sprite.spritesheet.width() and
          frame.rect.height <= sprite.spritesheet.height() and
          frame.rect.contains(frame.origin + vec2f(frame.rect.x.float, frame.rect.y.float))
        if not geometryGood:
          raise newException(ValueError, "Invalid Geometry for {0}".fmt($frame))

        # Make sure the frame isn't in there already
        if not (frame.name in sprite.frames):
          sprite.frames[frame.name] = frame

          # Is this the first frame that we are reading?
          if sprite.defaultFrameName.isNilOrEmpty():
            sprite.defaultFrameName = frame.name
        else:
          raise newException(NonUniqueNameError, "Frame name `{0}` already exists in the sprite".fmt(frame.name))

      # Read sequence info
      of ReadingSequenceInfo:
        # First check for state change
        if cl == SequenceInfoToken:
          continue                      # Skip line, we're already reading Sequence Info
        elif cl == FrameInfoToken:
          state = ReadingSequenceInfo   # Move to Frame Info
          continue

        # Create the sequence
        var sequence = Sequence(looping: false, frames: @[])

        # Line must be sequence info, nab some data
        let
          parts = removeWhitespace(cl).split('=')
          effectsStart = parts[0].find('[')
          effectsEnd = parts[0].find(']')

        # Are there effects?
        if (effectsStart != -1) and (effectsEnd != -1):
          # parse out the effects
          let effects = parts[0][(effectsStart + 1)..(effectsEnd - 1)].split(',')
          for e in effects:
            # Looping is the only effect right now
            if e == LoopingToken:
              sequence.looping = true
            else:
              # Not a known effect
              raise newException(InvalidEffectError, "`{0}` is not a valid effect".fmt(e))
        elif (effectsStart != -1) and (effectsEnd != -1):
          raise newException(ValueError, "Effects secttion is malformed")

        # Grab the name
        if effectsStart == -1:
          # No effects, whole thing is the name
          sequence.name = parts[0]
        else:
          # Must start before the effects list
          sequence.name = parts[0][0..(effectsStart - 1)]

        # Now parse out the timed frames
        let timedFrames = parts[1].split(',')
        for tfStr in timedFrames:
          let
            tfParts = tfStr.split(':')
            frame = sprite.frames[tfParts[0]]            # Get pointer to Frame via name, throw error if name not found
            hold = tfparts[1].parseInt().float / 1000.0  # Get hold value (and covert from ms to seconds)
          
          # Check that the TimeFrame is valid
          if hold <= 0:
            raise newException(ValueError, "Hold value for {0} in {1} must be non-negative".fmt(frame.name, hold))

          # Else, it's good, add it in to the sequence
          sequence.add(frame, hold)

        # Make sure the sequence isn't there either
        if not (sequence.name in sprite.sequences):
          sprite.sequences[sequence.name] = sequence
        else:
          raise newException(NonUniqueNameError, "Sequence name `{0}` already exists in the sprite".fmt(sequence.name))
      else:
        discard

  # close the file
  zspriteFile.close()

  # Last checks
  let
    atLeastOneFrame = sprite.frames.len() >= 1
    inTerminalState = (state == ReadingFrameInfo) or (state == ReadingSequenceInfo)
  if atLeastOneFrame and inTerminalState:
    state = Done

  if state != Done:
    log.debug("Didn't properly read a file.  Failed at state: " & $state)
    raise newException(ZSpriteLoadError, "Wasn't able to properly read the ZSprite at `{0}`".fmt(zspriteFilename))

  log.info("ZSprite with {0} frame(s) and {1} sequence(s) successfully loaded".fmt(sprite.frames.len(), sprite.sequences.len()))
  return sprite

