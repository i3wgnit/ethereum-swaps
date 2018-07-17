#lang racket

(require "evmasm.rkt")

;; This is a manually optimised version of the swap

(define constants
  '(;; Constants
    ;; ---------

    ;; Currently, there is no way to import files.
    ;; Actually I lied, this is how you do it


    (def scratch 0)

    (def _keyHash (+ s_keyHash 1))
    (def _expiration (+ s_expiration 1))
    (def _recipient (+ s_recipient 1))
    (def _deployer (+ s_deployer 1))

    (def claim #xbd66528a)
    (def expire #x79599f96)))

(define prog
  (append constants
  '(;; Constructor
    ;; -----------

    ;; 'sub_0 is the location of sub_0
    ;; (dataSize sub_0) is the bytesize of sub_0
    (codecopy scratch sub_0 (dup1 (dataSize sub_0)))

    (codecopy (+ scratch _keyHash) (dataSize bytecode) #x20)
    (codecopy (+ scratch _expiration) (+ (dataSize bytecode) #x20) #x20)
    (codecopy (+ scratch _recipient) (+ (dataSize bytecode) #x40) #x20)
    (mstore (+ scratch _deployer) (caller))

    ;; The assembler does not actually care how many inputs an element uses
    (return scratch)
    (stop)


    ;; Actual contract with functions
    ;; ------------------------------

    ;; This is sub_0
    (seq sub_0
         (;; ===
          ;; Functions declarations {
          ;; ===

          ;; Two copies of hash on the stack
          (dup1 (div (calldataload 0) (exp 2 #xe0)))

          ;; Payable functions
          ;; --

          ;; Not payable functions.
          (jumpi loc:invalid (gt (callvalue) 0))

          (jumpi fun:expire (eq expire))
          ;; If not calling expire, then use the second copy of hash
          (jumpi fun:claim (eq claim))

          ;; ===
          ;; } Functions declarations
          ;; ===

          ;; >
          ;; Labels don't add (jumpdest)
          (label loc:invalid)
          (invalid)


          ;; ===
          ;; Expire {
          ;; ===

          (dest fun:expire)
          ;; continue, if timestamp >= expiration
          (jumpi loc:invalid (lt (timestamp) #xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff (label s_expiration)))
          (selfdestruct #xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff (label s_deployer))
          (stop)

          ;; ===
          ;; } Expire
          ;; ===


          ;; ===
          ;; Claim {
          ;; ===

          (dest fun:claim)
          (dup1 #xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff (label s_recipient))

          ;; not(recipient == caller)
          (jumpi loc:invalid (iszero (eq (caller))))
          (mstore 0 (calldataload 4))
          (keccak256 0 #x20)

          ;; Check secret
          (jumpi loc:invalid (iszero (eq #xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff (label s_keyHash))))

          (selfdestruct)
          (stop)

          ;; ===
          ;; } Claim
          ;; ===
          )))))


(evm-assemble prog)
