;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname design) (read-case-sensitive #t) (teachpacks ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp"))) (htdp-settings #(#t constructor repeating-decimal #t #t none #f ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp")) #t)))
;; Kyle Corry

(define WIDTH 1000)
(define HEIGHT 500)

;; an animated-scene is (make-animated-scene list[graphic-object] list[cmd])
(define-struct animated-scene (shapes-used cmds))

;; a graphic-object is either
;; - (make-rectangle posn number number symbol symbol), or
;; - (make-circle posn number symbol symbol)
(define-struct rectangle (init-location width height color name))
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
                     [blue-rect (make-rectangle (make-posn 160 40) 20 200 'blue 'blue-rect)])
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
                     [gr-rect (make-rectangle (make-posn 30 100) 150 20 'green 'gr-rect)]
                     [red-rect (make-rectangle (make-posn 160 10) 20 80 'red 'red-rect)])
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
                     [my-square (make-rectangle (make-posn 100 50) 10 10 'blue 'my-square)]
                     [my-rect (make-rectangle (make-posn 50 100) 10 30 'green 'my-rect)])
                 (make-animated-scene
                  (list my-circle my-square my-rect)
                  (list (make-add-cmd 'my-circle)
                        (make-add-cmd 'my-square)
                        (make-do-forever-cmd (list (make-move-cmd 'my-circle (make-delta 20 10))))
                        (make-do-until-collision-cmd 'my-circle 'my-square empty (list (make-add-cmd 'my-rect)
                                                                                       (make-do-until-collision-cmd 'my-circle 'my-rect empty
                                                                                                                    (list (make-remove-cmd 'my-circle)))))))))
