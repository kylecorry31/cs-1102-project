;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname design) (read-case-sensitive #t) (teachpacks ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp"))) (htdp-settings #(#t constructor repeating-decimal #t #t none #f ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp")) #t)))
;; Kyle Corry

(define WIDTH 1000)
(define HEIGHT 500)

;; an animated-scene is (make-animated-scene list[cmd])
(define-struct animated-scene (cmds))

;; a graphic-object is either
;; - (make-rectangle posn number number symbol boolean), or
;; - (make-circle posn number symbol boolean)
(define-struct rectangle (location width height color visible?))
(define-struct circle (location radius color visible?))

;; a collision-object is either
;; - a graphic-object, or
;; - a symbol ('left-edge 'right-edge 'top-edge 'bottom-edge)


;; a cmd is either
;; - (make-add-cmd graphic-object)
;; - (make-remove-cmd graphic-object)
;; - (make-jump-cmd graphic-object posn)
;; - (make-move-cmd graphic-object delta)
;; - (make-do-until-collision-cmd graphic-object collision-object list[cmd] list[cmd])
;; - (make-do-forever-cmd list[cmd])
(define-struct add-cmd (shape))
(define-struct remove-cmd (shape))
(define-struct jump-cmd (shape location))
(define-struct move-cmd (shape velocity))
(define-struct do-until-collision-cmd (shape1 collides-with cmds-before cmds-after))
(define-struct do-forever-cmd (cmds))

;; a delta is (make-delta number number)
(define-struct delta (x y))

(define scene1 (let ([red-circle (make-circle (make-posn 20 40) 10 'red false)]
                     [blue-rect (make-rectangle (make-posn 160 40) 20 200 'blue false)])
                 (make-animated-scene
                  (list (make-add-cmd red-circle)
                        (make-add-cmd blue-rect)
                        (make-do-until-collision-cmd red-circle blue-rect
                                                     (list (make-move-cmd red-circle (make-delta 45 10)))
                                                     (list (make-remove-cmd blue-rect)
                                                           (make-do-until-collision-cmd red-circle 'left
                                                                                        (list (make-move-cmd red-circle (make-delta -160 10)))
                                                                                        empty)))))))

(define scene2 (let ([circ (make-circle (make-posn (random (+ 1 WIDTH)) (random (+ 1 HEIGHT))) 20 'purple false)])
                 (make-animated-scene
                  (list (make-add-cmd circ)
                        (make-do-until-collision-cmd circ 'top (list (make-jump-cmd circ (make-posn (random (+ 1 WIDTH)) (random (+ 1 HEIGHT)))))
                                                     empty)))))

(define scene3 (let ([circ (make-circle (make-posn 40 20) 15 'orange false)]
                     [gr-rect (make-rectangle (make-posn 30 100) 150 20 'green false)]
                     [red-rect (make-rectangle (make-posn 160 10) 20 80 'red false)])
                 (make-animated-scene
                  (list (make-add-cmd circ)
                        (make-add-cmd gr-rect)
                        (make-do-until-collision-cmd circ gr-rect
                                                     (list (make-move-cmd circ (make-delta 0 20)))
                                                     (list (make-add-cmd red-rect)
                                                           (make-do-until-collision-cmd circ red-rect
                                                                                        (list (make-move-cmd circ (make-delta 10 0)))
                                                                                        (list (make-jump-cmd circ (make-posn (random 211) (random 161)))))))))))


(define scene4 (let ([my-circle (make-circle (make-posn 0 0) 10 'red false)]
                     [my-square (make-rectangle (make-posn 100 50) 10 10 'blue false)]
                     [my-rect (make-rectangle (make-posn 50 100) 10 30 'green false)])
                 (make-animated-scene
                  (list (make-add-cmd my-circle)
                        (make-add-cmd my-square)
                        (make-do-forever-cmd (list (make-move-cmd my-circle (make-delta 20 10))))
                        (make-do-until-collision-cmd my-circle my-square empty (list (make-add-cmd my-rect)
                                                                                     (make-do-until-collision-cmd my-circle my-rect empty
                                                                                                                  (list (make-remove-cmd my-circle)))))))))
