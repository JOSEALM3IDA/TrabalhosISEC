breed [cats cat]
breed [mice mouse]
turtles-own [energy mayReproduce reproductionCD age]
globals [a b c d w z winner]

to setup
  ca
  set winner "no one"
  setup-patches
  setup-agents
  reset-ticks
end

to setup-patches
  ask patches [
    set pcolor brown

    if random 100 <= initFoodPerc [
      set pcolor green
    ]
  ]
end

to setup-agents
  create-mice N-mice [
    set shape "mouse side"
    set color white
    set age 0
    set mayReproduce 0
    set reproductionCD 0
    let x one-of patches with [pcolor != green]
    if x = nobody [
      set x one-of patches
    ]

    setxy [pxcor] of x [pycor] of x
    set energy initEnergy_Mice
  ]

  create-cats N-cats [
    set shape "cat"
    set color black
    set age 0
    set mayReproduce 0
    set reproductionCD 0
    let x one-of patches with [not any? mice-here and not any? mice-on neighbors and not any? cats-here and pcolor != green]
    if x = nobody [
      set x one-of patches
    ]

    setxy [pxcor] of x [pycor] of x
    set heading one-of [0 90 180 270]

    set energy initEnergy_Cats
  ]
end

to go
  check-status
  move-mice
  move-cats
  run-mice
  lunch-time
  reproduce-mice
  reproduce-cats
  tick
  regrow-food

  if ticks = 1000 [
    ifelse count mice > count cats [set winner "mice"] [set winner "cats"]
    stop
  ]

  if count mice = 0 [
    set winner "cats"
    stop
  ]

  if count cats = 0 [
    set winner "mice"
    stop
  ]
end

to regrow-food
  let i foodPerTick
  while [i > 0 and count patches with [pcolor = brown] / count patches > 0.25] [
    ask one-of patches with [pcolor != green] [
      set pcolor green
    ]

    set i i - 1
  ]
end

to check-status
  ask cats [
    if energy <= 0 [die]
    if age >= maxAgeCats and random 100 < oldAgeDeathChance [die]

    if reproductionCD <= 0 [
      set mayReproduce 1
    ]

    set reproductionCD reproductionCD - 1
    set age age + 1
  ]

  ask mice [
    if energy <= 0 [die]
    if age >= maxAgeMice and random 100 < oldAgeDeathChance [die]

    if reproductionCD <= 0 [
      set mayReproduce 1
    ]

    set reproductionCD reproductionCD - 1
    set age age + 1
  ]
end

to move-mice
  ask mice [
    let x 0
    ifelse any? neighbors with [pcolor = green and not any? cats-here] [
      set x one-of neighbors with [pcolor = green and not any? cats-here]
    ] [
      set x one-of neighbors with [not any? cats-here]
    ]

    ifelse x != nobody [move-to x] [move-to one-of neighbors]

    if [pcolor] of patch-here = green [
      set energy energy + foodGiven
      if energy > 100 [
        set energy 100
      ]

      set pcolor brown
    ]

    set energy energy - 1
  ]
end

to run-mice
  ask mice [
    if any? cats-on neighbors and energy > runCost[
      let x.cat 0
      let y.cat 0
      let x.mice xcor
      let y.mice ycor
      ask one-of cats-on neighbors [
        set x.cat xcor
        set y.cat ycor
      ]

      (ifelse x.cat = x.mice [
        ifelse y.cat > y.mice [
          set y.mice y.mice - 1
        ] [
          set y.mice y.mice + 1
        ]
      ] y.cat = y.mice [
          ifelse x.cat > x.mice [
          set x.mice x.mice - 1
        ] [
          set x.mice x.mice + 1
        ]
      ] y.cat > y.mice and x.cat > x.mice [
        set x.mice x.mice - 1
        set y.mice y.mice - 1
      ] y.cat < y.mice and x.cat < x.mice [
        set x.mice x.mice + 1
        set y.mice y.mice + 1
      ] y.cat > y.mice and x.cat < x.mice [
        set x.mice x.mice + 1
        set y.mice y.mice - 1
      ] y.cat < y.mice and x.cat > x.mice [
        set x.mice x.mice - 1
        set y.mice y.mice + 1
      ])

      ifelse not any? turtles-on patch x.mice y.mice [
        set xcor x.mice
        set ycor y.mice
      ] [ ;panico
        let x one-of neighbors with [not any? cats-here]
        move-to x
      ]

      set energy energy - runCost
    ]
  ]
end

to reproduce-mice
  ask mice with [mayReproduce = 1] [
    if any? mice-on neighbors and energy > reproductionEnergyMice and random 100 < reproductionChanceMice [
      let neighborCan 0
      ask one-of mice-on neighbors [
        if mayReproduce = 1 [
          set energy energy - reproductionEnergyMice
          set mayReproduce 0
          set reproductionCD reproductionCooldown

          set neighborCan 1
        ]
      ]
      if neighborCan = 1 [
        set energy energy - reproductionEnergyMice
        set mayReproduce 0
        set reproductionCD reproductionCooldown

        hatch 1 [
          set energy 25 + reproductionEnergyMice * 1.5
          set age 0
          set reproductionCD 0
        ]
      ]
    ]
  ]
end

to move-cats
  ask cats [
    ifelse any? mice-on patch-ahead 2 or any? mice-on patch-left-and-ahead 90 2 or any? mice-on patch-right-and-ahead 90 2
      [sniffing-cats] [random-walk-cats]
  ]
end

to sniffing-cats
  (ifelse any? mice-on patch-ahead 2 [
    ifelse energy > jumpCost [
      fd 2
      let mouse.energy 0
      ask mice-on patch-here [
        set mouse.energy energy
        die
      ]

      set energy energy + mouse.energy
      set energy energy - jumpCost
    ] [
      fd 1

      set energy energy - 1
    ]
  ] any? mice-on patch-left-and-ahead 90 2 [
    set heading heading - 90
    fd 1

    set energy energy - 1
  ] any? mice-on patch-right-and-ahead 90 2 [
    set heading heading + 90
    fd 1

    set energy energy - 1
  ])
end

to random-walk-cats
  if energy > 0 [
    if patch-ahead 1 != nobody [set a patch-ahead 1]
    if patch-ahead 2 != nobody [set b patch-ahead 2]
    if patch-right-and-ahead 90 1 != nobody [set c patch-right-and-ahead 90 1]
    if patch-right-and-ahead -90 1 != nobody [set d patch-right-and-ahead -90 1]
    if patch-right-and-ahead 45 1 != nobody [set w patch-right-and-ahead 45 1]
    if patch-right-and-ahead -45 1 != nobody [set z patch-right-and-ahead -45 1]
    let y (patch-set a b c d w z)
    let x one-of y with [not any? turtles-here]
    ifelse x != nobody [move-to x] [move-to one-of neighbors]
    if random 100 < 25 [set heading one-of [0 90 180 270]]

    set energy energy - 1
  ]
end

to reproduce-cats
  ask cats with [mayReproduce = 1] [
    if any? cats-on neighbors [
      if energy > reproductionEnergyCats + 10 and random 100 < reproductionChanceCats [
        let neighborCan 0
        ask one-of cats-on neighbors [
          if energy > reproductionEnergyCats + 10 and mayReproduce = 1 [
            set energy energy - reproductionEnergyCats
            set mayReproduce 0
            set reproductionCD reproductionCooldown
            set neighborCan 1
          ]
        ]
        if neighborCan = 1 [
          set energy energy - reproductionEnergyCats
          set mayReproduce 0
          set reproductionCD reproductionCooldown
          hatch 1 [
            set energy 25 + reproductionEnergyCats * 1.5
            set age 0
            set reproductionCD 0
          ]
        ]
      ]
    ]
  ]
end

to lunch-time
  ask mice [
    let mouse.energy energy
    if any? cats-on neighbors [
      ask cats-on neighbors[
        set energy energy + (mouse.energy * (energeticAbsorption / 100))
      ]
      die
    ]

    if any? cats-on patch-here [
      ask cats-on patch-here[
        set energy energy + (mouse.energy * (energeticAbsorption / 100))
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
465
35
988
559
-1
-1
15.61
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
10
55
182
88
N-mice
N-mice
0
40
25.0
1
1
NIL
HORIZONTAL

SLIDER
10
90
182
123
N-cats
N-cats
0
20
10.0
1
1
NIL
HORIZONTAL

BUTTON
10
10
76
43
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
80
10
143
43
NIL
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

MONITOR
355
420
412
465
NIL
ticks
17
1
11

PLOT
15
420
335
625
Agentes
NIL
NIL
0.0
40.0
0.0
40.0
true
true
"" ""
PENS
"Ratos" 1.0 0 -9276814 true "" "plot count mice"
"Gatos" 1.0 0 -2674135 true "" "plot count cats"

SLIDER
10
135
182
168
initFoodPerc
initFoodPerc
0
100
10.0
1
1
%
HORIZONTAL

BUTTON
148
10
213
43
NIL
go
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
230
55
402
88
initEnergy_Cats
initEnergy_Cats
0
100
70.0
1
1
NIL
HORIZONTAL

SLIDER
230
90
402
123
initEnergy_Mice
initEnergy_Mice
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
10
240
180
273
energeticAbsorption
energeticAbsorption
0
100
60.0
1
1
%
HORIZONTAL

SLIDER
10
205
182
238
foodGiven
foodGiven
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
10
170
182
203
foodPerTick
foodPerTick
0
20
8.0
1
1
NIL
HORIZONTAL

SLIDER
230
135
400
168
reproductionEnergyMice
reproductionEnergyMice
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
230
170
400
203
reproductionChanceMice
reproductionChanceMice
0
100
35.0
1
1
%
HORIZONTAL

SLIDER
10
290
182
323
jumpCost
jumpCost
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
230
290
402
323
runCost
runCost
0
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
230
205
400
238
reproductionEnergyCats
reproductionEnergyCats
0
100
35.0
1
1
NIL
HORIZONTAL

SLIDER
230
240
400
273
reproductionChanceCats
reproductionChanceCats
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
10
335
182
368
maxAgeCats
maxAgeCats
0
1000
450.0
1
1
ticks
HORIZONTAL

SLIDER
230
335
402
368
maxAgeMice
maxAgeMice
0
1000
150.0
1
1
ticks
HORIZONTAL

SLIDER
10
375
187
408
oldAgeDeathChance
oldAgeDeathChance
0
100
5.0
1
1
%
HORIZONTAL

MONITOR
355
470
412
515
ratos
count mice
17
1
11

MONITOR
355
520
412
565
gatos
count cats
17
1
11

SLIDER
230
375
400
408
reproductionCooldown
reproductionCooldown
0
100
25.0
1
1
ticks
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Os objetivos deste trabalho consiste em conceber, implementar e analisar comportamentos racionais  para  agentes reativos.

## HOW IT WORKS

Os  ratos  são  agentes  puramente  reativos. Conseguem percecionaras  8  células  na  suavizinhança  e  movem-se  para  uma delas.Não  têm  orientação  definida.

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

cat
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

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

mouse side
false
0
Polygon -7500403 true true 38 162 24 165 19 174 22 192 47 213 90 225 135 230 161 240 178 262 150 246 117 238 73 232 36 220 11 196 7 171 15 153 37 146 46 145
Polygon -7500403 true true 289 142 271 165 237 164 217 185 235 192 254 192 259 199 245 200 248 203 226 199 200 194 155 195 122 185 84 187 91 195 82 192 83 201 72 190 67 199 62 185 46 183 36 165 40 134 57 115 74 106 60 109 90 97 112 94 92 93 130 86 154 88 134 81 183 90 197 94 183 86 212 95 211 88 224 83 235 88 248 97 246 90 257 107 255 97 270 120
Polygon -16777216 true false 234 100 220 96 210 100 214 111 228 116 239 115
Circle -16777216 true false 246 117 20
Line -7500403 true 270 153 282 174
Line -7500403 true 272 153 255 173
Line -7500403 true 269 156 268 177

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="4.8" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count cats</metric>
    <metric>count mice</metric>
    <metric>ticks</metric>
    <metric>winner</metric>
    <enumeratedValueSet variable="N-mice">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initfoodPerc">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="foodPerTick">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="foodGiven">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initEnergy_Cats">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initEnergy_Mice">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energeticAbsorption">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproductionEnergymice">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproductionChanceMice">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproductionCooldown">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="jumpCost">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="runCost">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxAgeCats">
      <value value="450"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxAgeMice">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oldAgeDeathChance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproductionEnergyCats">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproductionChanceCats">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
