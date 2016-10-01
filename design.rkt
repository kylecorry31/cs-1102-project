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
(define WIDTH 1000)
(define HEIGHT 500)

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
                                                     (list (make-move-cmd 'red-circle (make-delta 45 10)))
                                                     (list (make-remove-cmd blue-rect)
                                                           (make-do-until-collision-cmd 'red-circle 'left-edge
                                                                                        (list (make-move-cmd 'red-circle (make-delta -160 10)))
                                                                                        empty)))))))

(define scene2 (let ([circ (make-circle (make-random-posn WIDTH HEIGHT) 20 'purple 'circ)])
                 (make-animated-scene
                  (list circ)
                  (list (make-add-cmd 'circ)
                        (make-do-until-collision-cmd 'circ 'top-edge (list (make-jump-cmd 'circ (make-random-posn WIDTH HEIGHT)))
                                                     empty)))))

(define scene3 (let ([circ (make-circle (make-posn 40 20) 15 'orange 'circ)]
                     [gr-rect (make-my-rect (make-posn 30 100) 150 20 'green 'gr-rect)]
                     [red-rect (make-my-rect (make-posn 160 10) 20 80 'red 'red-rect)])
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
                     [my-rect (make-my-rect (make-posn 50 100) 10 30 'green 'my-rect)])
                 (make-animated-scene
                  (list my-circle my-square my-rect)
                  (list (make-add-cmd 'my-circle)
                        (make-add-cmd 'my-square)
                        (make-do-forever-cmd (list (make-move-cmd 'my-circle (make-delta 20 10))))
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
        )))


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
    
    (begin (set-visiblility graphic-obj
                            false)
           ;;(remove-cmd-from-queue (cmd-var-id a-cmd))
           )))

;; draw-circle : circle scene -> scene
;; Draws a circle to the scene, returns the updated scene
(define (draw-circle circ a-scene)
  (place-image (ellipse (circle-radius circ)
                        (circle-radius circ)
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
                        






(define (animation-loop update-fn init-scene)
  (begin (update-frame (update-fn init-scene))
         (sleep/yield 0.25)
         (animation-loop update-fn init-scene)))