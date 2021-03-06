#lang racket

(define (eval exp env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((if? exp) (eval-if exp env))
        ((lambda? exp)
         (make-procedure (lambda-parameters exp)
                         (lambda-body exp)
                         env))
        ((let? exp) (let->combination exp env)) ;;;;;;;;;;;;;;;;;;;;;
        ((begin? exp) 
         (eval-sequence (begin-actions exp) env))
        ((cond? exp) (eval (cond->if exp) env))
        ((application? exp)
         (apply (eval (operator exp) env)
                (list-of-values (operands exp) env)))
        (else
         (error "Unknown expression type -- EVAL" exp))))

(define (let? exp) (tagged-list? exp 'let))
(define (let-parameters exp) (cadr exp))
(define (let-var exp) (map car exp))
(define (let-exp exp) (map cadr exp))
(define (named-let? exp)
  (and (let? exp) (not (pair? (let-parameters exp)))))
(define (let-var-named exp) (cadr exp))
(define (let-binding exp)
  (if (named-let? exp)
      (caddr exp)
      (error "Not named let -- no binding")))
(define (let-body exp)
  (if (named-let? exp)
      (cdddr exp)
      (cddr exp)))

(define (make-let parameters body)
  (cons 'let (cons parameters body)))

(define (let->combination exp env)
  (if (named-let? exp)
      (let ([exp-bindings-as-var (make-let (let-binding exp) (let-body exp))])
        (eval (make-begin
               (list
                ('define (cons (let-var-named exp) (let-var exp-bindings-as-var)) (let-body exp))
                (cons (let-var-named exp) (let-exp exp-bindings-as-var))))
              env))
      (eval (cons (make-lambda (let-var exp) (let-body exp)) (let-exp exp)) env)))

;For "named let", I turned the original form to 'define. E.g.,
;(define (fib n)
;  (let
;    fib-iter
;    ((a 1) (b 0) (count n))
;    (if (= count 0) b (fib-iter (+ a b) a (- count 1)))))
;========to=========>
;(define (fib n)
;  (define 
;    (fib-iter a b count)
;    (if (= count 0) b (fib-iter (+ a b) a (- count 1))))
;  (fib-iter 0 1 n))
