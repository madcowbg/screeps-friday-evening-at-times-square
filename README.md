# screeps-friday-evening-at-times-square
Advanced room navigation for ScreepsAI.

## Motivation
There are many great scripts to navigate around in rooms. Mostly up till now I have used [Traveler](https://github.com/bonzaiferroni/Traveler), which in contrast with the usual moveTo makes sure that roads are utilized to the max.

It is all find and dandy, until you bump into the poor maneuverability in tight places of these algorithms. Usually that happens when one or more of your creeps have to chill out on a road, and all traffic goes around them.

Inspired by the needs of [Ben Bartlett's bunker](https://bencbartlett.wordpress.com/2018/08/11/screeps-5-evolution/]) concept and his simple workaround, this package aims to create a much more general and optimized local navigator for overpopulated rooms.

The claim here is not a pathing algorithm - that is currently done by the standard `PathFinder.findPath`. The goal of this package is to achieve quick and efficient tight space maneuverability effortlessly.

## Dependencies and Set-up
This package uses [madcowbg/screeps-tools](https://github.com/madcowbg/screeps-tools) for the graph algorithms and the logging framework.

<!-- #TODO describe set-up - define target and targetDistance -->

## Algorithm
Since creeps cannot overlap, the basic idea is to find a path of shuffling that produces the smallest "inconvenience". This is achieved by generalizing the room state into a graph and finding shortest "path" using Dijkstra's algorithm.

The graph is dynamic, in order to reduce CPU usage in the most common case, i.e. just a couple of creeps trying to move next to each other.

Dijkstra's algorithm implementation

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
