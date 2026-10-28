/* mini SDK (see ../README.md): C11 atomics on the builtins of clang (the stdatomic.h of the
 * Android NDK's clang is bionic's, which needs bionic's sys/cdefs.h) */
#ifndef PNS_STDATOMIC_H
#define PNS_STDATOMIC_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef enum memory_order {
    memory_order_relaxed = __ATOMIC_RELAXED,
    memory_order_consume = __ATOMIC_CONSUME,
    memory_order_acquire = __ATOMIC_ACQUIRE,
    memory_order_release = __ATOMIC_RELEASE,
    memory_order_acq_rel = __ATOMIC_ACQ_REL,
    memory_order_seq_cst = __ATOMIC_SEQ_CST
} memory_order;

typedef _Atomic(bool) atomic_bool;
typedef _Atomic(int) atomic_int;
typedef _Atomic(unsigned int) atomic_uint;
typedef _Atomic(uint32_t) atomic_uint_least32_t;

#define ATOMIC_VAR_INIT(v) (v)
#define atomic_init(p, v) __c11_atomic_init(p, v)
#define atomic_thread_fence(o) __c11_atomic_thread_fence(o)
#define atomic_load_explicit(p, o) __c11_atomic_load(p, o)
#define atomic_store_explicit(p, v, o) __c11_atomic_store(p, v, o)
#define atomic_exchange_explicit(p, v, o) __c11_atomic_exchange(p, v, o)
#define atomic_fetch_add_explicit(p, v, o) __c11_atomic_fetch_add(p, v, o)
#define atomic_fetch_sub_explicit(p, v, o) __c11_atomic_fetch_sub(p, v, o)
#define atomic_compare_exchange_strong_explicit(p, e, v, s, f) __c11_atomic_compare_exchange_strong(p, e, v, s, f)
#define atomic_load(p) atomic_load_explicit(p, memory_order_seq_cst)
#define atomic_store(p, v) atomic_store_explicit(p, v, memory_order_seq_cst)
#define atomic_exchange(p, v) atomic_exchange_explicit(p, v, memory_order_seq_cst)
#define atomic_fetch_add(p, v) atomic_fetch_add_explicit(p, v, memory_order_seq_cst)

#endif
