extensions [ gis bitmap matrix table ]

; different types of agents with different behaviors, thieves, police, and civilians
breed [ thieves thief ]
breed [ police pol ]
breed [ civilians civilian ]

thieves-own [in-cone-of-vision]

police-own [current-cone-of-vision-range]

civilians-own [start-exit-point end-exit-point shortest-path-to-exit current-place-number current-flux-waiting-time]

globals [ robbed rate-of-change-robbed checkpoint-robbed checkpoint-ticks obstacles-bitmap flux-bitmap obstacles-matrix flux-matrix exit-points robbed-places-matrix]
; the number of agents is parametrized

to load-png-image-to-obstacles-bitmap
  set obstacles-bitmap bitmap:import "data/OstacoliCorretti.png"
  ; resize the bitmap to the size of the patches
  set obstacles-bitmap bitmap:scaled obstacles-bitmap world-width world-height
end

to load-png-image-to-flux-bitmap
  set flux-bitmap bitmap:import "data/Flussi.png"
  ; resize the bitmap to the size of the patches
  set flux-bitmap bitmap:scaled flux-bitmap world-width world-height
end

to load-png-image-to-flux-matrix
  ; load the image into the patches and copy the values to the flux-matrix
  import-pcolors-rgb "data/Flussi.png"
  set flux-matrix matrix:make-constant world-width world-height 0
  ask patches
  [ let this-pcolor pcolor
    ; convert the rgb plabel color to a grayscale value
    let flux-value (item 0 pcolor + item 1 pcolor + item 2 pcolor) / 3
    ; set the flux value to the corresponing flux-matrix place
    matrix:set flux-matrix pycor pxcor flux-value
  ]
end

to load-png-image-to-obstacles-matrix
  import-pcolors-rgb "data/OstacoliCorretti.png"
  set obstacles-matrix matrix:make-constant world-width world-height 0
  ask patches
  [ let this-pcolor pcolor
    ; convert the rgb plabel color to a grayscale value
    let obstacle-value (item 0 pcolor + item 1 pcolor + item 2 pcolor) / 3
    ; set the obstacle value to the corresponing obstacles-matrix place
    matrix:set obstacles-matrix pycor pxcor obstacle-value
  ]
end

to load-png-image-to-patches
    clear-all
    ; to change to the actual image
    import-pcolors-rgb "data/OstacoliCorretti.png"
    ask patches
    [ if pcolor = black
      [set plabel-color 0]
      if pcolor = [0 0 0]
      [set plabel-color 0]
      if pcolor != [255 255 255] and pcolor != [0 0 0]
      [set plabel-color 9.9
      set pcolor white]
    ]
end

; the agents cannot spawn in patches with grayscale value 0
to spawn-numberOfThieves-png
    create-thieves numberOfThieves
    [ setxy random-xcor random-ycor
        set color yellow
        set size 1
        set shape "person"
        set heading random 360
        set in-cone-of-vision false
        if pcolor = [0 0 0]
        [ die ]
    ]
end

to spawn-numberOfThieves-bitmap
    create-thieves numberOfThieves
    [ setxy random-xcor random-ycor
        set color yellow
        set size 1
        set shape "person"
        set heading random 360
        set in-cone-of-vision false
        if pcolor = [0 0 0]
        [ die ]
    ]
end

to spawn-numberOfThieves-matrix
    create-thieves numberOfThieves
    [ setxy random-xcor random-ycor
        set color yellow
        set size 1
        set shape "person"
        set heading random 360
        set in-cone-of-vision false
        if matrix:get obstacles-matrix pycor pxcor = 0
        [ die ]
    ]
end

to spawn-numberOfPolice-png
    create-police numberOfPolice
    [ setxy random-xcor random-ycor
        set color blue
        set size 1
        set shape "default"
        set heading random 360
        if pcolor = [0 0 0]
        [ die ]
    ]
end

to spawn-numberOfPolice-matrix
    create-police numberOfPolice
    [ setxy random-xcor random-ycor
        set color blue
        set size 1
        set shape "default"
        set heading random 360
        if matrix:get obstacles-matrix pycor pxcor = 0
        [ die ]
    ]
end

to spawn-numberOfCivilians-png
    create-civilians numberOfCivilians
    [ setxy random-xcor random-ycor
        set color green
        set size 1
        set shape "face happy"
        set heading random 360
        if pcolor = [0 0 0]
        [ die ]
    ]
end

to spawn-numberOfCivilians-matrix
    create-civilians numberOfCivilians
    [ setxy random-xcor random-ycor
        set color green
        set size 1
        set shape "face happy"
        set heading random 360
        if matrix:get obstacles-matrix pycor pxcor = 0
        [ die ]
    ]
end

to-report compute-shortest-path [startPoint endPoint]
  let startPatch patch (item 0 startPoint) (item 1 startPoint)
  let endPatch patch (item 0 endPoint) (item 1 endPoint)

  ; Initialize the BFS variables
  let queue (list startPoint)
  let cameFrom (table:make)
  table:put cameFrom startPoint nobody

  ; While there are patches to explore
  while [not empty? queue] [
    ; Get the current patch from the queue
    let current-pos first queue
    let current patch (item 0 current-pos) (item 1 current-pos)
    set queue but-first queue

    ; If we have reached the end point, reconstruct the path
    if (current = endPatch) [
      report reconstruct-path startPoint endPoint cameFrom
    ]

    ; Explore the neighbors of the current patch
    ask current[
      ask neighbors4 [
        let neighbor self
        let neighbor-xcor [pxcor] of neighbor
        let neighbor-ycor [pycor] of neighbor
        let neighbor-pos (list neighbor-xcor neighbor-ycor)
        ; Check if the neighbor is valid (not a wall and not visited)
        if matrix:get obstacles-matrix neighbor-ycor neighbor-xcor != 0 and not table:has-key? cameFrom neighbor-pos [
          ; Mark this neighbor as visited and add to the queue
          table:put cameFrom neighbor-pos current-pos
          set queue lput neighbor-pos queue
        ]
      ]
    ]
  ]

  ; If no path is found
  report []
end

to-report reconstruct-path [startPatch endPatch cameFrom]
  let path (list endPatch)
  let current endPatch

  while [current != startPatch] [
    set current table:get cameFrom current
    set path lput current path
  ]

  report reverse path
end


to spawn-numberOfCivilians-shortest-path [civilians-to-spawn]
  create-civilians civilians-to-spawn
  [let starting-exit-point item (random 8) exit-points
    let ending-exit-point item (random 8) exit-points
    ; reloop if the starting and ending exit points are the same
    while [starting-exit-point = ending-exit-point]
    [set ending-exit-point item (random 8) exit-points]
    set start-exit-point starting-exit-point
    set end-exit-point ending-exit-point
    set xcor (item 0 starting-exit-point)
    set ycor (item 1 starting-exit-point)
    set shortest-path-to-exit compute-shortest-path start-exit-point end-exit-point
    set current-place-number 0
    set color green
    set size 1
    set shape "face happy"
  ]
end

; police move in patches in a random direction, if a wall is present (values between 240 and 255) the police agent does not move
to move-police-png
    ask police
    [ wiggle
    ; if any patch in front of the police agent is a wall, the agent does not move
        ifelse any? patches in-cone 3 60 with [pcolor = [0 0 0]]
        [ wiggle ]
        [ fd 1 ]
        ;if pcolor != [0 0 0]
        ;[ fd 1 ]
    ]
end

to move-police-random-matrix
    ask police
    [ wiggle
    ; if any patch in front of the police agent is a wall, the agent does not move
        ifelse any? patches in-cone 3 60 with [matrix:get obstacles-matrix pycor pxcor = 0]
        [ wiggle ]
        [ fd 1 ]
    ]
end

to move-police-fixed-looking-at-most-robbed-place-in-radius
    ask police
  [ let most-robbed-place min-one-of patches in-radius coneOfVisionRange [matrix:get robbed-places-matrix pycor pxcor]
      if most-robbed-place != nobody
      [ face most-robbed-place
        ;fd 1
      ]
    ]
end

to move-thieves-png
    ask thieves
    [ wiggle
        ifelse any? patches in-cone 3 60 with [pcolor = [0 0 0]]
        [ wiggle ]
        [ fd 1 ]
    ]
end

to move-thieves-random-matrix
    ask thieves
    [ wiggle
        ifelse any? patches in-cone 3 60 with [matrix:get obstacles-matrix pycor pxcor = 0]
        [ wiggle ]
        [ fd 1 ]
    ]
end

to move-civilians-png
    ask civilians
    [ wiggle
        ifelse any? patches in-cone 3 60 with [pcolor = [0 0 0]]
        [ wiggle ]
        [ fd 1 ]
    ]
end

to move-civilians-random-matrix
    ask civilians
    [ wiggle
        ifelse any? patches in-cone 3 60 with [matrix:get obstacles-matrix pycor pxcor = 0]
        [ wiggle ]
        [ fd 1 ]
    ]
end

to move-civilians-shortest-path
  ask civilians
  [ if current-place-number < length shortest-path-to-exit
    [ let next-place item current-place-number shortest-path-to-exit
      let next-xcor item 0 next-place
      let next-ycor item 1 next-place
      face patch next-xcor next-ycor
      set xcor next-xcor
      set ycor next-ycor
      ;fd 1
      set current-place-number current-place-number + 1
    ]
  ]
end

; following the shortest path, but waiting proportional to the flux value of the patch
to move-civilians-shortest-path-with-flux
  ask civilians
  [ if current-place-number < length shortest-path-to-exit and current-flux-waiting-time = 0
    [ let next-place item current-place-number shortest-path-to-exit
      let next-xcor item 0 next-place
      let next-ycor item 1 next-place
      face patch next-xcor next-ycor
      set xcor next-xcor
      set ycor next-ycor
      ;fd 1
      set current-place-number current-place-number + 1
      set current-flux-waiting-time matrix:get flux-matrix next-ycor next-xcor
    ]
    if current-flux-waiting-time > 0
    [ set current-flux-waiting-time current-flux-waiting-time - 1
    ]
  ]
end

to wiggle
  left random 90
  right random 90
end

; a thief robs a civilian when the thief is in the same patch as the civilian
; if there is at least one police officer that is looking at the thief, the thief does not rob
to try-robbery
    ask thieves
    [ ifelse in-cone-of-vision
      [ set color blue]
      [set color yellow
        ask civilians-here
          [ set robbed robbed + 1
            matrix:set robbed-places-matrix pycor pxcor matrix:get robbed-places-matrix pycor pxcor + 1
          ]
      ]
;            [if any? neighbors with [pxcor = thief-xcor and pycor = thief-ycor]
;                [ set robbed robbed + 1]]
;        ]
    ]
end

to compute-robbed-rate
    set rate-of-change-robbed (robbed - checkpoint-robbed) / (ticks - checkpoint-ticks)
    set checkpoint-robbed robbed
    set checkpoint-ticks ticks
end

to clear-thieves
  ask thieves
  [set in-cone-of-vision false]
end

to reset-police-coneOfVision
  ask police
  [set current-cone-of-vision-range coneOfVisionRange]
end

to init-exit-points
  set exit-points [[65 148] [137 149] [2 122] [15 68] [142 87] [149 33] [93 8] [1 6]]
end

to respawn-civilians
  let civilians-to-respawn 0
  ask civilians
  [ if current-place-number >= length shortest-path-to-exit
    [ set civilians-to-respawn civilians-to-respawn + 1
      die
    ]
  ]
  spawn-numberOfCivilians-shortest-path civilians-to-respawn
end

to save-into-file-robbed-patches
  ask patches
  [ if matrix:get robbed-places-matrix pycor pxcor > 0
    [ file-open "robbed-patches.txt"
      file-print (word pycor " " pxcor " " matrix:get robbed-places-matrix pycor pxcor)
      file-close
    ]
  ]
end

to spawn-police-into-robbed-patches
  let robbed-patches-list []
  file-open "robbed-patches.txt"
  while [not file-at-end?]
  [ let temp-pycor file-read
    let temp-pxcor file-read
    let robbed-people file-read
    set robbed-patches-list lput (list temp-pycor temp-pxcor robbed-people) robbed-patches-list
  ]
  file-close
  show robbed-patches-list
  ; foreach robbed-patches-list
  ; [ let pycor item 0 ?
  ;   let pxcor item 1 ?
  ;   create-police
  ; sorted list of lists by the third element
  let sorted-list sort-by [[a b] -> item 2 a < item 2  b] robbed-patches-list
  show sorted-list
  foreach range numberOfPolice
  [ ; take the first element of the sorted list, that is the most robbed place
    let most-robbed-place first sorted-list
    show most-robbed-place
    let temp-pycor item 0 most-robbed-place
    let temp-pxcor item 1 most-robbed-place
    ; remove the most robbed place from the list
    set sorted-list but-first sorted-list
    create-police 1
    [ setxy temp-pxcor temp-pycor
      set color blue
      set size 1
      set shape "default"
      set heading random 360
    ]
    ; control if the list is empty
    if empty? sorted-list
    [ stop ]
  ]
end



to setup
    clear-all
    set robbed 0
    set robbed-places-matrix matrix:make-constant world-width world-height 0
    ; load-png-image-to-patches
    load-png-image-to-obstacles-bitmap
    load-png-image-to-flux-bitmap
    load-png-image-to-obstacles-matrix
    load-png-image-to-flux-matrix
    ; temporarly visualize obstacles bitmap
    ; bitmap:copy-to-pcolors obstacles-bitmap true
    ifelse showObstacles
    [ import-pcolors-rgb "data/OstacoliCorretti.png"]
    [ import-drawing "data/place.jpg"]
; creating the agents
    init-exit-points
    spawn-numberOfThieves-matrix
    ;spawn-numberOfPolice-matrix
    spawn-police-into-robbed-patches
;    spawn-numberOfCivilians-matrix
    spawn-numberOfCivilians-shortest-path numberOfCivilians
    reset-ticks
end

to go
    ; reset the color of the patches
    if showObstacles
    [ import-pcolors-rgb "data/OstacoliCorretti.png"]
    ; reset the thieves state
    clear-thieves
    ; compute the cone of vision for the police, if a wall is present, the police agent changes its cone of vision range to the distance between the agent and the wall
    ask police
    [ let police-xcor xcor
      let police-ycor ycor
      let final-cone-of-vision-range coneOfVisionRange
      ask patches in-cone coneOfVisionRange coneOfVisionAngle
      [ ;if pcolor = [0 0 0]
        if matrix:get obstacles-matrix pycor pxcor = 0
        [ let tmp-final-cone-of-vision-range distancexy police-xcor police-ycor
          if tmp-final-cone-of-vision-range < final-cone-of-vision-range
          [ set final-cone-of-vision-range tmp-final-cone-of-vision-range
          ]
        ]
      ]
      set current-cone-of-vision-range final-cone-of-vision-range
    ]
    ; show cone of vision for the police
    ask police
    [ ask patches in-cone current-cone-of-vision-range coneOfVisionAngle
      [ if matrix:get obstacles-matrix pycor pxcor = 255 and showConeOfVision
        [set pcolor red ]
        ; update state of thieves in cone of vision
        ask thieves-here
        [set in-cone-of-vision true
        ]
      ]
    ]
  ; move the agents
  ifelse police-behavior = "random"
  [
    move-police-random-matrix
  ]
  [
    move-police-fixed-looking-at-most-robbed-place-in-radius
  ]
  move-thieves-random-matrix
  ; move-civilians-random-matrix
  move-civilians-shortest-path-with-flux
  respawn-civilians
  try-robbery
  ; compute the rate of change of the number of robbed civilians after a defined number of ticks, given as a parameter
  if ticks - checkpoint-ticks  >= ticks-difference
  [
    compute-robbed-rate
  ]
  reset-police-coneOfVision
  tick
  ; save the number of robbed civilians, the ticks and the parameters of the model (police number, thieves number, civilians number, cone of vision range, cone of vision angle, police behavior) in a file
  if ticks mod 100 = 0
  [
    file-open "robbed.tsv"
    file-print (word robbed "\t" ticks "\t" numberOfPolice "\t" numberOfThieves "\t" numberOfCivilians "\t" coneOfVisionRange "\t" coneOfVisionAngle "\t" police-behavior)
    file-close
  ]
  if robbed = 2000
  [stop]
  if ticks = 10000
  [stop]
end
@#$#@#$#@
GRAPHICS-WINDOW
374
16
1679
1322
-1
-1
8.59
1
10
1
1
1
0
0
0
1
0
150
0
150
0
0
1
ticks
30.0

BUTTON
20
30
87
63
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
198
187
231
numberOfPolice
numberOfPolice
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
15
252
187
285
numberOfThieves
numberOfThieves
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
16
304
188
337
numberOfCivilians
numberOfCivilians
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
122
30
185
63
run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
19
361
197
394
coneOfVisionRange
coneOfVisionRange
0
50
19.0
1
1
NIL
HORIZONTAL

SLIDER
14
406
188
439
coneOfVisionAngle
coneOfVisionAngle
100
220
200.0
1
1
NIL
HORIZONTAL

SWITCH
12
461
189
494
showConeOfVision
showConeOfVision
0
1
-1000

MONITOR
11
514
69
559
NIL
robbed
17
1
11

PLOT
13
587
213
737
robbed people
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot robbed"

CHOOSER
32
145
170
190
ticks-difference
ticks-difference
10 100 1000
1

PLOT
13
748
213
898
rate of change
NIL
NIL
0.0
10.0
10.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot rate-of-change-robbed"

SWITCH
19
94
173
127
showObstacles
showObstacles
1
1
-1000

CHOOSER
14
914
152
959
police-behavior
police-behavior
"random" "fixed-looking"
1

BUTTON
23
976
188
1009
save robbed patches
save-into-file-robbed-patches
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
