log = require 'tools.log'

{coordToN, nToCoord, adjacencyOffset} = require 'tools.coordinates'
{dijstraSlowDynamic, path} = require 'tools.adt.graph'

MAX_STUCK_CNT = 2

Creep::moveToTarget = () ->
  if @fatigue > 0 or @spawning or not (isFarFromTarget this)
    log.info? "#{@name} is fiiine, dude, no need to move."
    return

  updateNavigationPath this
  moveInstruction = nextMoveInstruction this

  if moveInstruction?
    log.info? "#{@name} will try moving from #{JSON.stringify @pos} to #{JSON.stringify moveInstruction}"
    @room.navigation.attemptMoveToAdjacent @, @room.getPositionAt(moveInstruction.x, moveInstruction.y)

updateNavigationPath = (creep) ->
  navData = creep.memory._navigationData ?=
    path: []
    stuckCounter: 0

  updatePositionInPath creep, navData
  if not (isPathUpToDate creep.pos, navData.path) or navData.stuckCounter >= MAX_STUCK_CNT
    log.info? "#{creep.name}'s stuck or nav cache is incorrect, searching for path to target."
    initializeCreepPath creep, navData

nextMoveInstruction = (creep) ->
  _.first creep.memory._navigationData?.path

initializeCreepPath = (creep, navData) ->
  navData.path = creep.pos.findPathTo creep.target, {
    range: creep.targetDistance
    ignoreCreeps: (navData.stuckCounter < MAX_STUCK_CNT)
  }
  navData.stuckCounter -= 1

isFarFromTarget = (creep) ->
  creep.target? and not creep.pos.inRangeTo creep.target, creep.targetDistance

isPathUpToDate = (currentPos, path) ->
  path.length > 0 and isAdjacentPosition currentPos, path[0]

isEqualPosition = (posA, posB) ->
  posA.x == posB.x and posA.y == posB.y

isAdjacentPosition = (posA, posB) ->
  (Math.max Math.abs(posA.x - posB.x), Math.abs(posA.y - posB.y)) <= 1

updatePositionInPath = (creep, navData) ->
  if navData.prevPos? and (isEqualPosition creep.pos, navData.prevPos)
    navData.stuckCounter += 1
  navData.prevPos = creep.pos

  while navData.path.length > 0 && isEqualPosition navData.path[0], creep.pos
    log.info? "#{creep.name} skips already traversed #{JSON.stringify navData.path[0]}"
    navData.path.shift()

Object.defineProperty Room.prototype, 'navigation', {
  get: () -> @_navigation ?= new RoomNavigation @
  enumerable: false
}

class RoomNavigation
  constructor: (@room) ->
    @nextPlaceOfCreep = {}
    @scheduledNextOccupant = {}

    @creeps = @room.find FIND_MY_CREEPS
    for creep in @creeps
      @markNext creep, creep.pos

  markNext: (creep, pos) ->
    @nextPlaceOfCreep[creep.name] = pos
    @scheduledNextOccupant[coordToN pos] = creep

    status = creep.move creep.pos.getDirectionTo(pos.x, pos.y)
    if status != OK
      new Error "move of #{creep.name} failed with status = #{status}."

  vacatePlaceOf: (creep) ->
    delete @scheduledNextOccupant[coordToN @nextPlaceOfCreep[creep.name]]
    delete @nextPlaceOfCreep[creep.name]

  shuffleCreepsOnPath: (creepToMove, shufflePath) ->
    while (place = shufflePath.pop())?
      nextCreep = @scheduledNextOccupant[place.label]
      log.info? "moving #{creepToMove.name} to #{JSON.stringify nToCoord place.label}"
      @markNext creepToMove, (nToCoord place.label)
      creepToMove = nextCreep

  attemptMoveToAdjacent: (creep, nextPos) ->
    log.info? "#{creep.name} tries moving through #{JSON.stringify nextPos}."
    @vacatePlaceOf creep

    graph = new DynamicCreepShuffleGraph @room, @scheduledNextOccupant
    startVertex = graph.vertex nextPos

    posVertex = dijstraSlowDynamic startVertex, graph.cost, graph.isEmptyPos, dist={}, verticesParent={}

    unless posVertex?
      log.error "Cannot shuffle others so that #{creep.name} can move!"
      return

    log.info? "creeps shuffle path ok - place #{dumpVertex posVertex} is free!"
    @shuffleCreepsOnPath creep, (path posVertex, verticesParent)


class DynamicCreepShuffleGraph
  constructor: (@room, @positionToOccupant) ->
    @_cachedVertices = {}

    @cost = (fv, tv) =>
      @calculateVertexCost fv, tv

    @isEmptyPos = (v) =>
      not @positionToOccupant[v.label]?

  vertex: (pos) ->
    positionLabel = coordToN pos
    return @_cachedVertices[positionLabel] ?=
      label: positionLabel
      adjacent: @nextCreepPossibilities positionLabel

  calculateVertexCost: (fv, tv) ->
    creep = @positionToOccupant[fv.label]
    {x, y} = nToCoord tv.label

    if not (isRetainingTarget creep, x, y)
      return 20

    nextInstr = nextMoveInstruction creep

    if nextInstr? and isEqualPosition nextInstr, {x, y}
      return 0

    if nextInstr? and isAdjacentPosition nextInstr, {x, y}
      if hasRoadOn @room, x, y
        return 0.5
      else
        return 1

    if hasRoadOn @room, x, y
      return 1.5

    return 2

  nextCreepPossibilities: (positionLabel) -> () =>
    creep = @positionToOccupant[positionLabel]
    return _.compact (if not creep? then [] else @feasibleNextPosition creep, dx, dy for [dx, dy] in adjacencyOffset)

  feasibleNextPosition: (creep, dx, dy) ->
    [x, y] = [creep.pos.x + dx, creep.pos.y + dy]
    if 0 <= x < 49 and 0 <= y < 49 and (positionPassableThisTurn @room, x, y)
      @vertex {x, y}

# FIXME: immobile or hostile creeps?
positionPassableThisTurn = (room, x, y) -> isPassableThisTurn room, x, y
isRetainingTarget = (creep, x, y) -> not (isNearTarget creep) or (creep.target.pos.inRangeTo x, y, creep.targetDistance)

dumpVertex = (posVertex) -> JSON.stringify nToCoord posVertex.label
dumpPath = (posVertex, verticesParent) -> JSON.stringify(nToCoord s.label for s in (path posVertex, verticesParent).reverse())

isPassableThisTurn = (room, x, y) ->
  (room._isPassableThisTurn ?= {})[coordToN {x, y}] ?= geographyAndStructuresArePassable room, x, y

hasRoadOn = (room, x, y) ->
  (room._hasRoadOn ?= {})[coordToN {x, y}] ?= roomHasRoadOn room, x, y

roomHasRoadOn = (room, x, y) ->
  for s in (room.lookForAt LOOK_STRUCTURES, x, y)
    if s.structureType == STRUCTURE_ROAD
      return true
  return false

isWallAt = (room, x, y) ->
  (room.memory._isWallAt ?= {})[coordToN {x, y}] ?= (room.lookForAt LOOK_TERRAIN, x, y)[0] == 'wall'

geographyAndStructuresArePassable = (room, x, y) ->
  if isWallAt room, x, y
    return false

  for s in (room.lookForAt LOOK_STRUCTURES, x, y)
    if _.includes OBSTACLE_OBJECT_TYPES, s.structureType
      return false
  return true

isNearTarget = (creep) -> creep.target? and creep.pos.inRangeTo creep.target, creep.targetDistance
