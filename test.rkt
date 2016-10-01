(require "world-cs1102.rkt")

(create-canvas 1000 1000)

(define test-image (rectangle 120 120 'solid 'black))

(define test-scene (empty-scene 1000 1000))

(define image-coords (make-posn 0 0))


(update-frame (place-image test-image 0 0 test-scene))

(define (test-update sn)
  (begin
    (set! image-coords (make-posn (+ 20 (posn-x image-coords))
                                  (+ 1 (posn-y image-coords))))
    (let [(x (posn-x image-coords))
          (y (posn-y image-coords))]
      (place-image test-image x y sn))))



(define (animation-loop update-fn init-scene)
  (begin (update-frame (update-fn init-scene))
         (sleep/yield 0.25)
         (animation-loop update-fn init-scene)))

(animation-loop test-update test-scene)

