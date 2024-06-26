; Employee Compensation Optimisation Simulation

; Define global variables.
globals [
  successful-job-changes    ; The number of successful job changes.
  successful-negotiations   ; The number of successful negotiations.
  initial-salary            ; The salary (ZAR) that all agents will initially start with.
]

; Define agents.
breed [employers employer]
breed [employees employee]

; Define agent attributes.
employees-own [
  salary                    ; Monthly salary in ZAR.
  my-employer               ; Current employer.
  tenure                    ; Time spent with current employer.
  tendency                  ; Whether the employee tends to stay in the same job or change.
  tipping-point             ; The point at which an employee who tends to stay will change.
]

employers-own [
  num-jobs-available        ; Number of job openings currently available.
  workforce-needs           ; Number of employees needed to fulfil company needs.
  capacity                  ; Total number of employees company can have.
  my-employees              ; Agentset of employees.
]

; Set up routine.
to setup
  clear-all

  ; Initialise global variables.
  set successful-job-changes 0
  set successful-negotiations 0
  set initial-salary random-normal 50000 25000

  ; Create employers and position them in a grid in the top half.
  let employer-spacing (max-pxcor - min-pxcor) / (ceiling (sqrt num-employers) + 1)
  let employer-num 0

  create-employers num-employers [
    set shape "circle 2"
    set color yellow
    set capacity (random 96) + 5
    set workforce-needs random capacity
    set num-jobs-available 0
    set my-employees []
    set size 1

    ; Position the employer in a grid in the top half.
    let row floor (employer-num / ceiling (sqrt num-employers))
    let col employer-num mod ceiling (sqrt num-employers)
    let x-pos (col * employer-spacing) + min-pxcor + (employer-spacing / 2)
    let y-pos max-pycor - (row * employer-spacing) - (employer-spacing / 2) + 2
    setxy x-pos y-pos
    set employer-num employer-num + 1
  ]

  ; Create employees and position them in a grid in the bottom half.
  create-employees num-employees [
    set shape "person business"
    set color random color
    set salary 0
    set tenure 0
    set tendency one-of ["stay" "change"]
    set tipping-point random-float 0.15 + 0.15

    ; Position the employee in the bottom half.
    let x-pos random-xcor
    let y-pos random min-pycor
    setxy x-pos y-pos
  ]

  reset-ticks
end

; Go routine.
to go

  ask employers [
    eval-workforce-needs
  ]

  let application-outcome random-float 1.0              ; Simulate application process.
  ask employees [
    if-else my-employer = 0 and application-outcome > 0.5 [                                     ; If unemployed, apply for job.
      seek-job
    ] [
      if-else tendency = "stay" [                       ; If employee tends to stay, only apply for job if salary increase is greater or equal to their tipping point.
        if-else application-outcome > 0.5 and salary-increase-changing-jobs >= tipping-point [  ; Application successful.
          seek-job
        ] [
          negotiate                                     ; Either appplication unsuccessful or salary increase is less than tipping point, so negotiate for raise.
        ]
      ] [                                               ; Else, employee tends to change so apply for job.
          if-else application-outcome > 0.5 [           ; Application successful.
            seek-job
          ] [
            negotiate                                   ; Application unsuccessful, so negotiate for raise.
          ]
      ]
      set salary max (list (salary * (1 - inflation)) 0)                                        ; Apply inflation, up to a min salary of 0.
    ]
  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;; EMPLOYER ROUTINES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to eval-workforce-needs
  if workforce-needs > length my-employees [                                                    ; First check if workforce needs are not being met.
    if length my-employees < capacity [                                                         ; If so, check that capacity hasn't been exceeded.
      set num-jobs-available workforce-needs - length my-employees                              ; Open a post.
    ]
  ]

  set size length my-employees / 4                                                              ; Update size of company, scaled down by 4 for visual display.
end

;;;;;;;;;;;;;;;;;;;;;; EMPLOYEE ROUTINES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to seek-job
  if-else any? employers with [num-jobs-available > 0] [            ; Check if there are jobs available.
    let new-employer one-of employers with [num-jobs-available > 0] ; Choose one employer with available jobs.
    let old-employer my-employer
    set my-employer new-employer                                    ; Update my employer.

    ask new-employer [                                              ; Update new employer details.
      set num-jobs-available num-jobs-available - 1
      set my-employees fput myself my-employees
    ]

    if old-employer != 0 [
      ask old-employer [                                            ; Update old employer details.
        set num-jobs-available num-jobs-available + 1
        set my-employees remove myself my-employees
      ]
    ]

    if-else salary = 0 [                                            ; If unemployed, set salary to initial salary.
     set salary initial-salary
    ] [
      set salary min (list (salary * (1 + salary-increase-changing-jobs)) 1000000)    ; Update salary, up to a max of 1 million.
    ]

    move-to new-employer                                            ; Move to new employer and reset number of years at employer.
    set tenure 0

    set successful-job-changes successful-job-changes + 1           ; Increment number of job changes.
  ] [
    set salary min (list (salary * (1 + annual-salary-increase)) 1000000)             ; If no jobs available, update salary with annual increase, up to a max of 1 million.
    set tenure tenure + 1                                                             ; Increase number of years at employer.
  ]
end

to negotiate
  let negotiation-outcome random-float 1.0                          ; Simulate negotiation process.

  if-else negotiation-outcome > 0.5 [                               ; Negotiation successful.
    set salary min (list (salary * (1 + salary-increase-negotiation)) 10000000)       ; Update salary, up to a max of 1 million.

    set successful-negotiations successful-negotiations + 1         ; Increment number of successful negotiations.
  ] [                                                               ; Negotiation unsuccessful.
    set salary min (list (salary * (1 + annual-salary-increase)) 1000000)             ; Update salary with annual increase, up to a max of 1 million.
  ]

  set tenure tenure + 1                                             ; Increase number of years at employer.
end

;;;;;;;;;;;;;;;;;;;;;;;;; REPORTERS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report sum-num-jobs-available
  report sum [num-jobs-available] of employers
end

to-report total-successful-job-changes
  report successful-job-changes
end

to-report total-successful-negotiations
  report successful-negotiations
end

to-report avg-salary-job-changers
  report mean [salary] of employees with [tendency = "change"]
end

to-report avg-salary-non-job-changers
  report mean [salary] of employees with [tendency = "stay"]
end

to-report total-job-changers
  report count employees with [tenure < 5]
end

to-report total-non-job-changers
  report count employees with [tenure >= 5]
end
@#$#@#$#@
GRAPHICS-WINDOW
5
267
251
514
-1
-1
4.86
1
12
1
1
1
0
0
0
1
-24
24
-24
24
1
1
1
ticks
30.0

SLIDER
5
48
251
81
num-employees
num-employees
0
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
5
84
251
117
num-employers
num-employers
1
50
10.0
1
1
NIL
HORIZONTAL

BUTTON
5
9
72
43
Setup
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

BUTTON
76
10
140
44
Step
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

BUTTON
145
10
209
44
Go
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
5
120
252
153
annual-salary-increase
annual-salary-increase
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
6
193
251
226
salary-increase-changing-jobs
salary-increase-changing-jobs
0
1
0.15
0.01
1
NIL
HORIZONTAL

MONITOR
257
408
457
453
Number of Job Openings
sum-num-jobs-available
17
1
11

MONITOR
257
460
457
505
Successful Job Changes
successful-job-changes
0
1
11

MONITOR
256
511
456
556
Successful Negotiations
successful-negotiations
17
1
11

SLIDER
6
230
252
263
inflation
inflation
0
1
0.06
0.01
1
NIL
HORIZONTAL

PLOT
257
10
994
396
Average Salaries
Ticks
Salary
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Changers" 1.0 0 -16777216 true "" "plot mean [salary] of employees with [tendency = \"change\"]"
"Stayers" 1.0 0 -2674135 true "" "plot mean [salary] of employees with [tendency = \"stay\"]"

MONITOR
708
407
854
452
Changers Average Salary
avg-salary-job-changers
2
1
11

MONITOR
709
457
833
502
Tenure < 5
total-job-changers
0
1
11

MONITOR
858
406
994
451
Stayers Average Salary
avg-salary-non-job-changers
2
1
11

MONITOR
836
457
994
502
Tenure >= 5
total-non-job-changers
0
1
11

SLIDER
6
156
251
189
salary-increase-negotiation
salary-increase-negotiation
0
1
0.1
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the relationship between employee tenures at companies and compensation. This tests the notion that changing jobs more frequently leads to better compensation in a shorter period of time.

## HOW IT WORKS

This model creates a number of employers and employees. At each step, each employer evaluates its workforce needs and adjusts its number of job openings accordingly. At each step, the employees decide whether they want to stay in their job and negotiate for a promotion or if they want to apply for a new job.

Employees have a tendency (stayers/changers) which influences which decision they make at each tick. Stayers have a tipping point which is a random value at which they will forego their tendency.

## HOW TO USE IT

- `num-employees` - The number of employees in the simulation.
- `num-employers` - The number of employers in the simulation.
- `annual-salary-increase` - The annual salary increase an employer will receive if un-
successful for both applying for a job and negotiating.
- `salary-increase-negotiation` - The salary increase that an employer receives upon a successful negotiation for a raise.
- `salary-increase-changing-jobs` - The salary increase that an employer receives upon successfully changing jobs.
- `inflation` - The annual inflation applied at each time step.

## THINGS TO NOTICE

Which group performs better? Stayers or Changers?

How fast does one group reach a plateau versus the other?

What are the numbers of employees with Tenure < 5 compared to those >= 5?

How do the numbers of successful negotiations compare with successful job changes?

## THINGS TO TRY

Try reducing the salary increase from changing jobs to match the annual salary increase/salary increase from negotiation to see how that affects salaries.

Try reducing the number of employers/increasing the number of employees to see the effect on number of available jobs and how that relates to the salaries.

Play around with the inflation to see the effects of inflation on salaries.

Adjust values to match average values of other countries to see if they are consistent to South Africa.

## EXTENDING THE MODEL

Introduce age to the employees and have willingness to change jobs be a function of their age. Older people tend to not want to move around too much!

Empower the employers more. Have different types of employers. Some that frown upon employees who move around too much. Some that want to hire more youth.

Introduce a job satisfaction property on the employees and track that as employees move around.

## RELATED MODELS

* Wilensky, U. (2011).  NetLogo Simple Economy model.  http://ccl.northwestern.edu/netlogo/models/SimpleEconomy.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

## CREDITS AND REFERENCES

* Muzambi, T. (2024).  Optimising Compensation model.  https://modelingcommons.org/browse/one_model/7408#model_tabs_browse_info
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

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

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
<experiments>
  <experiment name="Vary Changing Jobs Increase" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>avg-salary-job-changers</metric>
    <metric>avg-salary-non-job-changers</metric>
    <enumeratedValueSet variable="num-employers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="salary-increase-negotiation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inflation">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-employees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="salary-increase-changing-jobs">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-salary-increase">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vary Inflation" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>avg-salary-job-changers</metric>
    <metric>avg-salary-non-job-changers</metric>
    <enumeratedValueSet variable="num-employers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="salary-increase-negotiation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inflation">
      <value value="0"/>
      <value value="0.02"/>
      <value value="0.04"/>
      <value value="0.06"/>
      <value value="0.08"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-employees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="salary-increase-changing-jobs">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-salary-increase">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vary Number of Employers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>avg-salary-job-changers</metric>
    <metric>avg-salary-non-job-changers</metric>
    <enumeratedValueSet variable="num-employers">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="salary-increase-negotiation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inflation">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-employees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="salary-increase-changing-jobs">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-salary-increase">
      <value value="0.05"/>
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
0
@#$#@#$#@
