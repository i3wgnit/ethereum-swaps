#lang racket
(require "evmasm.rkt")

(define program
  '(;; Definitions
    (def secretHash #x91d6a24697ed31932537ae598d3de3131e1fcd0641b9ac4be7afcb376386d71e)
    (def timelock #x5b2e7d47)

    (def redeemPKH #x5acbf79d0cf4139a6c3eca85b41ce2bd23ced04f)
    (def refundPKH #x0a81e8be41b21f651a71aab1a85c6813b8bbccf8)

    ;; Constructor
    (dup1 (dataSize contract))
    (codecopy 0 contract)
    (return 0)

    ;; Contract
    (seq contract
         (;; ===
          ;; Check secretHash {
          ;; ===

          ;; Pull secret and apply SHA256
          (dup1 32)
          (calldatacopy 0 0)
          (call #x48 #x2 #x0 #x0 (dup2) #x21)

          ;; Compare computed secretHash with given one
          (eq (mload #x21) secretHash)

          ;; Verify that call indeed returned something
          (and)

          ;; ===
          ;; }
          ;; ===

          ;; If secret hash is good, redeem
          (jumpi label:redeem)

          ;; ===
          ;; Check timelock {
          ;; ===

          (gt (timestamp) timelock)

          ;; ===
          ;; }
          ;; ===

          ;; If timelock passed, refund
          (jumpi label:refund)

          ;; Else, halt
          (stop)

          (dest label:redeem)
          (suicide redeemPKH)

          (dest label:refund)
          (suicide refundPKH)))))

(evm-assemble program)
