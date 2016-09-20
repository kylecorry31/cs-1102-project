;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname project) (read-case-sensitive #t) (teachpacks ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp"))) (htdp-settings #(#t constructor repeating-decimal #t #t none #f ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp")) #t)))
;; Kyle Corry

#|
1. What kind of data is this language designed to process?

   Shapes are the data. They have different sizes, shapes (circle or rectangle),
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

;; a delta is (make-delta number number)
(define-struct delta (x y))

;; a shape is either
;;   - (make-rectangle posn number number), or
;;   - (make-circle posn number)

(define-struct rectangle (location width height))
(define-struct circle (location radius))

;; a collision-object is either
;;  - a shape, or
;;  - a posn

;; a cmd is either
;;   - (make-movecmd shape delta), or
;;   - (make-jumpcmd shape posn), or
;;   - (make-deletecmd shape), or
;;   - (make-createcmd shape), or
;;   - (make-collidecmd shape collision-object cmd)
(define-struct movecmd (a-shape velocity))
(define-struct jumpcmd (a-shape a-posn))
(define-struct deletecmd (a-shape))
(define-struct createcmd (a-shape))
(define-struct collidecmd (a-shape collides-with a-cmd))

;; an animated-scene is (make-animated-scene list[cmd])
(define-struct animated-scene (cmdlist))

(define scene1 (let ([my-circle (make-circle (make-posn 0 0) 10)]
                     [my-square (make-rectangle (make-posn 100 50) 10 10)]
                     [my-rect (make-rectangle (make-posn 50 100) 10 30)])
                 (make-animated-scene
                  (list (make-createcmd my-circle)
                        (make-createcmd my-square)
                        (make-movecmd my-circle (make-delta 20 10))
                        (make-collidecmd my-circle my-square (make-createcmd my-rect))
                        (make-collidecmd my-circle my-rect (make-deletecmd my-circle))))))