#lang racket

(define (enclosing-environment env) (cdr env)) ;same
(define (first-frame env) (car env)) ;same
(define the-empty-environment '()) ;same

(define (make-frame variables values)
  (define (make-frame-iter variables values)
    (cond ((and (null? variables) (null? values)) '())
          ((null? values) (error "Too many arguments supplied" variables values))
          ((null? variables) (error "Too few arguments supplied" variables values))
          (else (cons (cons (car variables) (car values))
                      (make-frame-iter (cdr variables) (cdr values))))))
  (make-frame-iter variables values))
(define (frame-variables frame) (map car frame))
(define (frame-values frame) (map cdr frame))
(define (add-binding-to-frame! var val frame)
  (set! frame (cons (cons var val) frame)))

(define (extend-environment vars vals base-env) ;same
  (if (= (length vars) (length vals))
      (cons (make-frame vars vals) base-env)
      (if (< (length vars) (length vals))
          (error "Too many arguments supplied" vars vals)
          (error "Too few arguments supplied" vars vals))))

(define (lookup-variable-value var env)
  (define (env-loop env)
    (define (scan frame)
      (cond ((null? frame) (env-loop (enclosing-environment env)))
            ((eq? var (car (car frame))) (cdr (car frame)))
            (else (scan (cdr frame)))))
    (if (eq? env the-empty-environment)
        (error "Unbound variable" var)
        (let ((frame (first-frame env)))
          (scan frame))))
  (env-loop env))

(define (set-variable-value! var val env)
  (define (env-loop env)
    (define (scan frame)
      (cond ((null? frame) (env-loop (enclosing-environment env)))
            ((eq? var (car (car frame))) (set-cdr! (car frame) val))
            (else (scan (cdr frame)))))
    (if (eq? env the-empty-environment)
        (error "Unbound variable -- SET!" var)
        (let ((frame (first-frame env)))
          (scan frame))))
  (env-loop env))

(define (define-variable! var val env)
  (define (scan frame)
    (cond ((null? vars) (add-binding-to-frame! var val (first-frame env)))
          ((eq? var (car (car frame))) (set-cdr! (car frame) val))
          (else (scan (cdr frame)))))
  (scan (first-frame env)))
