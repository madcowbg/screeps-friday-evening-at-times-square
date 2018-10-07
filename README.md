# screeps-friday-evening-at-times-square
Advanced room navigation for ScreepsAI.

## Motivation
There are many great scripts for pathfinding in Screeps. Up till now I have used mostly  [Traveler](https://github.com/bonzaiferroni/Traveler), which, in contrast with the usual moveTo, makes sure that roads are utilized to the maximum and only moves off them if there is a blockage.

It is all find and dandy, until you bump into the poor maneuverability in tight places. Usually that happens when one or more of your creeps have to chill out on a road, and all traffic goes around them - which is bad if you have optimized your move parts. Moreover, some layouts are tight and would suffer under such conditions.

Inspired by the needs of [Ben Bartlett's bunker](https://bencbartlett.wordpress.com/2018/08/11/screeps-5-evolution/]) concept and his simple workaround, this package aims to create a much more general and optimized local navigator for overpopulated rooms.

The claim here is not a pathing algorithm - that is currently done by the standard `PathFinder.findPath`. The goal of this package is to achieve quick and efficient tight space maneuverability effortlessly.

## Use and Dependencies

What needs for this to work is to have all creeps assigned properties:
 - `creep.target` - the game object which is our target - _Note: this is NOT the id of the object, but the current game object._,
 - `creep.targetDistance` - the distance to target that needs to be achieved.

It is easier to define the above as properties, so that the `creep.target` is always an up-to-date object.

Then the only thing that remains is to call `creep.moveToTarget()` so that the creep is moved.

_Note: that all creeps in the room will be reshuffled when needed. If they do not have assigned a target, they will be shuffled aggressively._

Some additional dependencies are needed. This package uses [madcowbg/screeps-tools](https://github.com/madcowbg/screeps-tools) for the graph algorithms and the logging framework. Just copy the JS versions in your AI folder.

## Algorithm
Since creeps cannot overlap, the basic idea is to find a path of shuffling that produces the smallest "inconvenience". This is achieved by generalizing the room state into a graph and finding shortest "path" using Dijkstra's algorithm.

The graph is dynamic, in order to reduce CPU usage in the most common case, i.e. just a couple of creeps trying to move past each other.

Dijkstra's algorithm implementation is O(V^2), which is slow, but fast enough and simple.

## Screenshots
Here are some, over-exaggerated use cases. Nobody in their right mind will use that many creeps, that is too CPU intensive, but the algorithm will handle it.

### A spectacle occurs
First, what about the usual case of having many upgraders trying to get to upgrade? Easy, just set their `creep.target` to the controller, `creep.targetDistance` to 3 and let them figure it out...

![screeps get to mass without interruption](https://github.com/madcowbg/screeps-friday-evening-at-times-square/blob/master/screenshots/upgraders_galore_fast.gif?raw=true)

### Every good thing has an end
Then we get back to work. Oops, the road is right next to the source, so how are we to use it?

Easy - just let the creeps push themselves around a bit.

![screeps find their way in a jam](https://github.com/madcowbg/screeps-friday-evening-at-times-square/blob/master/screenshots/in_a_jam.gif?raw=true)

### Directions for improvement
Use [Traveler](https://github.com/bonzaiferroni/Traveler)'s fast and optimized long distance pathing algorithm.
