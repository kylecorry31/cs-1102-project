;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname design) (read-case-sensitive #t) (teachpacks ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp"))) (htdp-settings #(#t constructor repeating-decimal #t #t none #f ((lib "dir.rkt" "teachpack" "htdp") (lib "matrix.rkt" "teachpack" "htdp")) #t)))
;; Kyle Corry

;; an animated-scene is (make-animated-scene list[cmd])
(define-struct animated-scene (cmds))

;; a graphic-object is either
;; - (make-rectangle posn number number symbol boolean), or
;; - (make-circle posn number symbol boolean)
(define-struct rectangle (location width height color visible?))
(define-struct circle (location radius color visible?))


;; a cmd is either
;; - (make-add-cmd graphic-object)
;; - (make-remove-cmd graphic-object)
;; - (make-jump-cmd graphic-object posn)
;; - (make-move-cmd graphic-object delta)
;; - (make-do-until-collision-cmd graphic-object graphic-object list[cmd] list[cmd])
;; - (make-do-forever-cmd list[cmd])
(define-struct add-cmd (shape))
(define-struct remove-cmd (shape))
(define-struct jump-cmd (shape location))
(define-struct move-cmd (shape velocity))
(define-struct do-until-collision-cmd (shape1 shape2 cmds-before cmds-after))
(define-struct do-forever-cmd (cmds))

;; a delta is (make-delta number number)
(define-struct delta (x y))

(define scene1 (let ([my-circle (make-circle (make-posn 0 0) 10 'red false)]
                     [my-square (make-rectangle (make-posn 100 50) 10 10 'blue false)]
                     [my-rect (make-rectangle (make-posn 50 100) 10 30 'green false)])
                 (make-animated-scene
                  (list (make-add-cmd my-circle)
                        (make-add-cmd my-square)
                        (make-do-forever-cmd (list (make-move-cmd my-circle (make-delta 20 10))))
                        (make-do-until-collision-cmd my-circle my-square empty (list (make-add-cmd my-rect)
                                                                                     (make-do-until-collision-cmd my-circle my-rect empty
                                                                                                                  (list (make-remove-cmd my-circle)))))))))
