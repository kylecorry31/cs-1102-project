;; Kyle Corry

#|
1. What kind of data is this language designed to process?

   Shapes are the data. They have different sizes, shapes (circle or my-rect),
   and positions.


2. What operations can someone perform on the data?

   Animations act on the data which can move, jump, delete, create,
   or respond to shape collisions.


3. What control operators do I need to sequence operations?

   Shapes are displayed by their order (linear), and the collision operation
   can call another operation depending on whether the shape is colliding with
   something.


4. What work is the language saving the programmer from doing?

   The language should save the programmer from definining what makes a collision
   It should also save the programmer from needing to draw the shapes to the screen and
   and manually moving shapes pixelwise.

|#

(require "world-cs1102.rkt")

;; To be used on the canvas later, and for examples
(define WIDTH 400)
(define HEIGHT 350)

;; an animated-scene is (make-animated-scene list[graphic-object] list[cmd])
(define-struct animated-scene (shapes-used cmds))

;; a graphic-object is either
;; - (make-my-rect posn number number symbol symbol), or
;; - (make-circle posn number symbol symbol)
(define-struct my-rect (init-location width height color name))
(define-struct circle (init-location radius color name))

;; a jump-posn is either
;; - a posn
;; - (make-random-posn number number)
(define-struct random-posn (width height))


;; a cmd is either
;; - (make-add-cmd symbol)
;; - (make-remove-cmd symbol)
;; - (make-jump-cmd symbol jump-posn)
;; - (make-move-cmd symbol delta)
;; - (make-do-until-collision-cmd symbol symbol list[cmd] list[cmd])
;; - (make-do-forever-cmd list[cmd])
(define-struct add-cmd (shape))
(define-struct remove-cmd (shape))
(define-struct jump-cmd (shape location))
(define-struct move-cmd (shape velocity))
(define-struct do-until-collision-cmd (shape1 collides-with cmds-before cmds-after))
(define-struct do-forever-cmd (cmds))

;; a delta is (make-delta number number)
(define-struct delta (x y))



(define scene1 (let ([red-circle (make-circle (make-posn 20 40) 10 'red 'red-circle)]
                     [blue-rect (make-my-rect (make-posn 160 40) 20 200 'blue 'blue-rect)])
                 (make-animated-scene
                  (list red-circle blue-rect)
                  (list (make-add-cmd 'red-circle)
                        (make-add-cmd 'blue-rect)
                        (make-do-until-collision-cmd 'red-circle 'blue-rect
                                                     (list (make-move-cmd 'red-circle (make-delta 15 5)))
                                                     (list (make-remove-cmd 'blue-rect)
                                                           (make-do-until-collision-cmd 'red-circle 'left-edge
                                                                                        (list (make-move-cmd 'red-circle (make-delta -16 10)))
                                                                                        empty)))))))

(define scene2 (let ([circ (make-circle (make-posn 100 100) 20 'purple 'circ)])
                 (make-animated-scene
                  (list circ)
                  (list (make-add-cmd 'circ)
                        (make-do-until-collision-cmd 'circ 'top-edge (list (make-jump-cmd 'circ (make-random-posn WIDTH HEIGHT)))
                                                     empty)))))

(define scene3 (let ([circ (make-circle (make-posn 40 20) 15 'orange 'circ)]
                     [gr-rect (make-my-rect (make-posn 30 100) 150 20 'green 'gr-rect)]
                     [red-rect (make-my-rect (make-posn 160 50) 20 80 'red 'red-rect)])
                 (make-animated-scene
                  (list circ gr-rect red-rect)
                  (list (make-add-cmd 'circ)
                        (make-add-cmd 'gr-rect)
                        (make-do-until-collision-cmd 'circ 'gr-rect
                                                     (list (make-move-cmd 'circ (make-delta 0 20)))
                                                     (list (make-add-cmd 'red-rect)
                                                           (make-do-until-collision-cmd 'circ 'red-rect
                                                                                        (list (make-move-cmd 'circ (make-delta 10 0)))
                                                                                        (list (make-jump-cmd 'circ (make-random-posn 210 160))))))))))


(define scene4 (let ([my-circle (make-circle (make-posn 0 0) 10 'red 'my-circle)]
                     [my-square (make-my-rect (make-posn 100 50) 10 10 'blue 'my-square)]
                     [my-rect (make-my-rect (make-posn 180 90) 10 30 'green 'my-rect)])
                 (make-animated-scene
                  (list my-circle my-square my-rect)
                  (list (make-add-cmd 'my-circle)
                        (make-add-cmd 'my-square)
                        (make-do-forever-cmd (list (make-move-cmd 'my-circle (make-delta 10 5))))
                        (make-do-until-collision-cmd 'my-circle 'my-square empty (list (make-add-cmd 'my-rect)
                                                                                       (make-do-until-collision-cmd 'my-circle 'my-rect empty
                                                                                                                    (list (make-remove-cmd 'my-circle)))))))))



;;;;;;;;;;;;;;;;;;;;;;;;; Interpreter ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; a shape-var is (make-shape-var symbol graphic-object boolean)
(define-struct shape-var (name shape visible))

;; a cmd-var is (make-cmd-var number cmd)
(define-struct cmd-var (id cmd))

(define init-shapes empty)

(define cmd-queue empty)

;; run-animation : animated-scene number number -> void
;; Displays and runs an animated scene with the given width and height
(define (run-animation an-animation width height)
  (begin
    (create-canvas width height)
    (set! init-shapes empty)
    (set! cmd-queue empty)
    (set-init-shapes (animated-scene-shapes-used an-animation))
    (set-cmd-queue (animated-scene-cmds an-animation) 0)
    (animation-loop (lambda (sn) (run-cmds cmd-queue sn)) (empty-scene width height))
    (void)))


;; set-cmd-queue : list[cmd] number -> void
;; (side-effect) Creates a variable for each of the cmds in a list of cmds starting from the starting id
(define (set-cmd-queue cmds starting-id)
  (cond[(empty? cmds) empty]
       [(cons? cmds)
        (begin (set! cmd-queue (append
                                cmd-queue
                                (list (make-cmd-var starting-id (first cmds)))))
               (set-cmd-queue (rest cmds) (+ 1 starting-id)))]))



;; set-init-shapes : list[graphic-object] -> void
;; (side-effect) Creates a variable for each of the shapes in a list of graphic objects
(define (set-init-shapes lgo)
  (cond[(empty? lgo) empty]
       [(cons? lgo)
        (begin (set! init-shapes (append init-shapes
                                         (list (make-shape-var (cond[(circle? (first lgo)) (circle-name (first lgo))]
                                                                    [(my-rect? (first lgo)) (my-rect-name (first lgo))])
                                                               (first lgo)
                                                               false))))
               (set-init-shapes (rest lgo)))]))


;; run-cmds : list[cmd] scene -> scene
;; Runs all animation cmds in a list of cmds
(define (run-cmds loc init-scene)
  (cond[(empty? loc) init-scene]
       [(cons? loc)
        (run-cmds (rest loc) (run-cmd (first loc) init-scene))]))

;; run-cmd : cmd-var scene -> scene
;; Runs a cmd on the scene and (side-effect) removes the one time cmd from the queue or repeats a repetive cmd
(define (run-cmd a-cmd a-scene)
  (let [(cmd (cmd-var-cmd a-cmd))]
    (cond [(add-cmd? cmd) (add-shape a-cmd a-scene)]
          [(remove-cmd? cmd) (begin (remove-shape a-cmd)
                                    a-scene)]
          [(jump-cmd? cmd) (begin (jump-shape a-cmd)
                                  a-scene)]
          [(move-cmd? cmd) (begin (move-shape a-cmd)
                                  a-scene)]
          [(do-forever-cmd? cmd) (begin (set-cmd-queue (do-forever-cmd-cmds cmd) (+ 1 (max-cmd-id cmd-queue)))
                                        a-scene)]
          [(do-until-collision-cmd? cmd) (begin (handle-collision-cmd a-cmd a-scene)
                                                a-scene)]
          )))


;; max-cmd-id : list[cmd-var] -> number
;; Gets the max cmd id from a list of cmd-vars
(define (max-cmd-id cmds)
  (apply max (map cmd-var-id cmds)))

;; get-shape : symbol -> graphic-obj
;; Gets the graphic obj from the init-shapes with the given name
(define (get-shape name)
  (shape-var-shape (first (filter (lambda (var)
                                    (symbol=? (shape-var-name var) name)) init-shapes))))

;; add-shape : cmd-var scene -> scene
;; Adds a graphic-object to the scene, (side-effect) removes the add-cmd from the queue
(define (add-shape a-cmd a-scene)
  (let [(graphic-obj (get-shape (add-cmd-shape (cmd-var-cmd a-cmd))))]
    (let [(updated-scene (cond[(circle? graphic-obj) (draw-circle graphic-obj a-scene)]
                              [(my-rect? graphic-obj) (draw-my-rect graphic-obj a-scene)]))]
      (begin
        
        (set-visibility (cond[(circle? graphic-obj) (circle-name graphic-obj)]
                             [(my-rect? graphic-obj) (my-rect-name graphic-obj)]
                             )
                        true)
        ;;(remove-cmd-from-queue (cmd-var-id a-cmd))
        updated-scene))))


;; remove-shape : cmd-var -> void
;; Sets the visibility of the given shape shape to false
(define (remove-shape a-cmd)
  (let [(graphic-obj (remove-cmd-shape (cmd-var-cmd a-cmd)))]
    
    (begin (set-visibility graphic-obj
                           false)
           (remove-cmd-from-queue (cmd-var-id a-cmd))
           (map remove-cmd-from-queue (map cmd-var-id (filter (lambda (cmd)
                                                                (cond[(add-cmd? (cmd-var-cmd cmd)) (symbol=? graphic-obj (add-cmd-shape (cmd-var-cmd cmd)))]
                                                                     [else false]))
                                                              cmd-queue))))))


;; jump-shape : cmd-var -> void
;; (side-effect) Moves a shape to a given position
(define (jump-shape cv)
  (begin (set! init-shapes (map (lambda (shape)
                                  (cond [(symbol=? (jump-cmd-shape (cmd-var-cmd cv)) (shape-var-name shape))
                                         (let [(s (shape-var-shape shape))
                                               (loc (cond[(posn? (jump-cmd-location (cmd-var-cmd cv))) (jump-cmd-location (cmd-var-cmd cv))]
                                                         [(random-posn? (jump-cmd-location (cmd-var-cmd cv)))
                                                          (let [(rand (jump-cmd-location (cmd-var-cmd cv)))]
                                                            (make-posn (random (random-posn-width rand)) (random (random-posn-height rand))))]))]
                                           
                                           (make-shape-var (shape-var-name shape) (cond[(circle? s) (make-circle loc
                                                                                                                 (circle-radius s)
                                                                                                                 (circle-color s)
                                                                                                                 (circle-name s))]
                                                                                       [(my-rect? s) (make-my-rect loc
                                                                                                                   
                                                                                                                   (my-rect-width s)
                                                                                                                   (my-rect-height s)
                                                                                                                   (my-rect-color s)
                                                                                                                   (my-rect-name s))]) (shape-var-visible shape)))]
                                        [else shape])
                                  ) init-shapes))
         (remove-cmd-from-queue (cmd-var-id cv))
         ))

;; move-shape : cmd-var -> void
;; (side-effect) Moves a shape by a given delta
(define (move-shape cv)
  (begin (set! init-shapes (map (lambda (shape)
                                  (cond [(symbol=? (move-cmd-shape (cmd-var-cmd cv)) (shape-var-name shape))
                                         (let [(s (shape-var-shape shape))]
                                           (make-shape-var (shape-var-name shape) (cond[(circle? s) (make-circle (add-delta (move-cmd-velocity (cmd-var-cmd cv))
                                                                                                                            (circle-init-location s))
                                                                                                                 (circle-radius s)
                                                                                                                 (circle-color s)
                                                                                                                 (circle-name s))]
                                                                                       [(my-rect? s) (make-my-rect (add-delta (move-cmd-velocity (cmd-var-cmd cv))
                                                                                                                              (my-rect-init-location s))
                                                                                                                   (my-rect-width s)
                                                                                                                   (my-rect-height s)
                                                                                                                   (my-rect-color s)
                                                                                                                   (my-rect-name s))]) (shape-var-visible shape)))]
                                        [else shape])
                                  ) init-shapes))
         (remove-cmd-from-queue (cmd-var-id cv))
         ))

;; handle-collision-cmd : cmd-var scene -> void
;; Do a set of commands until a collision occurs, then run the rest of the commands after collision (side-effect: if collision, cmd will be deleted)
(define (handle-collision-cmd cmd a-scene)
  (let [(collision-cmd (cmd-var-cmd cmd))]
    (cond[(collision? (do-until-collision-cmd-shape1 collision-cmd) (do-until-collision-cmd-collides-with collision-cmd) (image-width a-scene) (image-height a-scene))
          (begin (set-cmd-queue (do-until-collision-cmd-cmds-after collision-cmd) (+ 1 (max-cmd-id cmd-queue)))
                 (remove-cmd-from-queue (cmd-var-id cmd)))]
         [else (run-cmds (map (lambda (c)
                                (make-cmd-var (+ 1 (max-cmd-id cmd-queue)) c))
                              (do-until-collision-cmd-cmds-before collision-cmd)) a-scene)])))


;; shape-top-edge : graphic-object -> number
;; Determines the top edge y value of a graphic-object
(define (shape-top-edge shape)
  (cond[(circle? shape) (- (posn-y (circle-init-location shape)) (circle-radius shape))]
       [(my-rect? shape) (- (posn-y (my-rect-init-location shape)) (/ (my-rect-height shape) 2))]))

;; shape-bottom-edge : graphic-object -> number
;; Determines the bottom edge y value of a graphic-object
(define (shape-bottom-edge shape)
  (cond[(circle? shape) (+ (posn-y (circle-init-location shape)) (circle-radius shape))]
       [(my-rect? shape) (+ (posn-y (my-rect-init-location shape)) (/ (my-rect-height shape) 2))]))

;; shape-left-edge : graphic-object -> number
;; Determines the left edge x value of a graphic-object
(define (shape-left-edge shape)
  (cond[(circle? shape) (- (posn-x (circle-init-location shape)) (circle-radius shape))]
       [(my-rect? shape) (- (posn-x (my-rect-init-location shape)) (/ (my-rect-width shape) 2))]))

;; shape-right-edge : graphic-object -> number
;; Determines the right edge x value of a graphic-object
(define (shape-right-edge shape)
  (cond[(circle? shape) (+ (posn-x (circle-init-location shape)) (circle-radius shape))]
       [(my-rect? shape) (+ (posn-x (my-rect-init-location shape)) (/ (my-rect-width shape) 2))]))

;; graphic-objects-collide graphic-object graphic-object -> boolean
;; Determines if two graphic objects are colliding
(define (graphic-objects-collide? shape1 shape2)
  (and (< (shape-top-edge shape1) (shape-bottom-edge shape2))
       (< (shape-top-edge shape2) (shape-bottom-edge shape1))
       (< (shape-left-edge shape1) (shape-right-edge shape2))
       (< (shape-left-edge shape2) (shape-right-edge shape1))))

;; collision? : symbol symbol number number -> boolean
;; Determines if two objects collide
(define (collision? shape1 collides-with scene-width scene-height)
  (let [(shape (get-shape shape1))]
    (cond[(symbol=? 'left-edge collides-with)
          (< (shape-left-edge shape) 0)]
         [(symbol=? 'right-edge collides-with)
          (> (shape-right-edge shape) scene-width)]
         [(symbol=? 'top-edge collides-with)
          (< (shape-top-edge shape) 0)]
         [(symbol=? 'bottom-edge collides-with)
          (> (shape-bottom-edge shape) scene-height)]
         [else (graphic-objects-collide? shape (get-shape collides-with))])))



;; draw-circle : circle scene -> scene
;; Draws a circle to the scene, returns the updated scene
(define (draw-circle circ a-scene)
  (place-image (ellipse (* 2 (circle-radius circ))
                        (* 2 (circle-radius circ))
                        'solid
                        (circle-color circ))
               (posn-x (circle-init-location circ))
               (posn-y (circle-init-location circ))
               a-scene))

;; draw-my-rect : my-rect scene -> scene
;; Draws a my-rect to the scene, returns the updated scene
(define (draw-my-rect rect a-scene)
  (place-image (rectangle (my-rect-width rect)
                          (my-rect-height rect)
                          'solid
                          (my-rect-color rect))
               (posn-x (my-rect-init-location rect))
               (posn-y (my-rect-init-location rect))
               a-scene))


;; set-visibility : symbol boolean
;; (side-effect) Sets the visibility of the shape with the given name in the init-shapes to the given visibility
(define (set-visibility name visibility)
  (set! init-shapes (map (lambda (sv)
                           (cond[(symbol=? name (shape-var-name sv)) (make-shape-var (shape-var-name sv)
                                                                                     (shape-var-shape sv)
                                                                                     visibility)]
                                [else sv]))
                         init-shapes)))

;; remove-cmd-from-queue : number -> void
;; (side-effect) Removes the cmd with the given id from the cmd-queue
(define (remove-cmd-from-queue id)
  (set! cmd-queue (filter (lambda (cv)
                            (not (= id (cmd-var-id cv)))
                            ) cmd-queue)))



;; add-delta : delta posn -> posn
;; Adds a delta to a posn
(define (add-delta vel loc)
  (make-posn (+ (posn-x loc)
                (delta-x vel))
             (+ (posn-y loc)
                (delta-y vel))))



(define (animation-loop update-fn init-scene)
  (begin (update-frame (update-fn init-scene))
         (sleep/yield 0.25)
         (animation-loop update-fn init-scene)))