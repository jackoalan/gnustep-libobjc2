#ifndef PPC_ATOMIC_H
#define PPC_ATOMIC_H


/* The following inline definitions are derived from
 * the OpenPA 'portable atomics' project
 *
 *  (C) 2008 by Argonne National Laboratory.
 *      See COPYRIGHT at:
 *      https://github.com/jackoalan/openpa/blob/master/COPYRIGHT
 */

#  define OPA_ATTRIBUTE(x_) __attribute__ (x_)

/* these need to be aligned on an 8-byte boundary to work on a BG/P */
typedef struct { volatile int v    OPA_ATTRIBUTE((aligned (8))); } OPA_int_t;
typedef struct { void * volatile v OPA_ATTRIBUTE((aligned (8))); } OPA_ptr_t;


static inline int OPA_LL_int(OPA_int_t *ptr)
{
    int val;
    __asm__ __volatile__ ("lwarx %[val],0,%[ptr]"
                          : [val] "=r" (val)
                          : [ptr] "r" (&ptr->v)
                          : "cc");
    
    return val;
}

static inline int OPA_SC_int(OPA_int_t *ptr, int val)
{
    int ret = 1;
    __asm__ __volatile__ ("stwcx. %[val],0,%[ptr];\n"
                          "beq 1f;\n"
                          "li %[ret], 0;\n"
                          "1: ;\n"
                          : [ret] "=r" (ret)
                          : [ptr] "r" (&ptr->v), [val] "r" (val), "0" (ret)
                          : "cc", "memory");
    return ret;
}

static inline int OPA_add_int_and_fetch_by_llsc(OPA_int_t *ptr, int val)
{
    int prev;
    do {
        prev = OPA_LL_int(ptr);
    } while (!OPA_SC_int(ptr, prev + val));
    return OPA_LL_int(ptr);
}

static inline int OPA_sub_int_and_fetch_by_llsc(OPA_int_t *ptr, int val)
{
    int prev;
    do {
        prev = OPA_LL_int(ptr);
    } while (!OPA_SC_int(ptr, prev - val));
    return OPA_LL_int(ptr);
}

static inline int OPA_cas_int_by_llsc(OPA_int_t *ptr, int oldv, int newv)
{
    int prev;
    do {
        prev = OPA_LL_int(ptr);
    } while (prev == oldv && !OPA_SC_int(ptr, newv));
    return prev;
}

static inline void *OPA_LL_ptr(OPA_ptr_t *ptr)
{
    void *val;
    __asm__ __volatile__ ("lwarx %[val],0,%[ptr]"
                          : [val] "=r" (val)
                          : [ptr] "r" (&ptr->v)
                          : "cc");
    
    return val;
}

static inline int OPA_SC_ptr(OPA_ptr_t *ptr, void *val)
{
    int ret = 1;
    __asm__ __volatile__ ("stwcx. %[val],0,%[ptr];\n"
                          "beq 1f;\n"
                          "li %[ret], 0;\n"
                          "1: ;\n"
                          : [ret] "=r" (ret)
                          : [ptr] "r" (&ptr->v), [val] "r" (val), "0" (ret)
                          : "cc", "memory");
    return ret;
}

static inline void *OPA_cas_ptr_by_llsc(OPA_ptr_t *ptr, void *oldv, void *newv)
{
    void *prev;
    do {
        prev = OPA_LL_ptr(ptr);
    } while (prev == oldv && !OPA_SC_ptr(ptr, newv));
    return prev;
}

#define __sync_bool_compare_and_swap_int(ref,test,repl) (test == OPA_cas_int_by_llsc((OPA_int_t*)ref,test,repl))
#define __sync_bool_compare_and_swap_ptr(ref,test,repl) (test == OPA_cas_ptr_by_llsc((OPA_ptr_t*)ref,test,repl))
#define __sync_add_and_fetch(ref,addval) OPA_add_int_and_fetch_by_llsc((OPA_int_t*)ref,addval)
#define __sync_sub_and_fetch(ref,subval) OPA_sub_int_and_fetch_by_llsc((OPA_int_t*)ref,subval)


#endif
