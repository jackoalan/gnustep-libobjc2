/**
 * libobjc requires recursive mutexes.  These are delegated to the underlying
 * threading implementation.  This file contains a VERY thin wrapper over the
 * Windows and POSIX mutex APIs.
 */

#ifndef __LIBOBJC_LOCK_H_INCLUDED__
#define __LIBOBJC_LOCK_H_INCLUDED__
#ifdef WIN32
#define BOOL _WINBOOL
#	include <windows.h>
#undef BOOL
typedef HANDLE mutex_t;
#	define INIT_LOCK(x) x = CreateMutex(NULL, FALSE, NULL)
#	define LOCK(x) WaitForSingleObject(*x, INFINITE)
#	define UNLOCK(x) ReleaseMutex(*x)
#	define DESTROY_LOCK(x) CloseHandle(*x)
#else

// Squeeze WiiStep in here
#ifdef WIISTEP

#if WIISTEP_RVL_SDK // Use Nintendo's OS API for thread-sync

#include <revolution/os.h>
typedef OSMutex mutex_t;
#define INIT_LOCK(x) OSInitMutex(&x)
#define LOCK(x) OSLockMutex(&x)
#define UNLOCK(x) OSUnlockMutex(&x)
#define DESTROY_LOCK(x) // All memory usage is within OSMutex object

#elif WIISTEP_LIBOGC // Use libogc LWP API for thread-sync

#include <ogc/mutex.h>
#include <unistd.h>
#include <ogcsys.h>
#include <stdio.h>
extern struct timespec slp_tm;
#define SLEEP() sleep(1)
// Libogc conveniently defines mutex_t
#define INIT_LOCK(x) LWP_MutexInit(&x,0)
#define LOCK(x) LWP_MutexLock(*x)
#define UNLOCK(x) LWP_MutexUnlock(*x)
#define DESTROY_LOCK(x) LWP_MutexDestroy(*x)

#endif // Done choosing platform library

#else // NOT WIISTEP
#	include <pthread.h>

typedef pthread_mutex_t mutex_t;
// If this pthread implementation has a static initializer for recursive
// mutexes, use that, otherwise fall back to the portable version
#	ifdef PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP
#		define INIT_LOCK(x) x = PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP
#	elif defined(PTHREAD_RECURSIVE_MUTEX_INITIALIZER)
#		define INIT_LOCK(x) x = (pthread_mutex_t)PTHREAD_RECURSIVE_MUTEX_INITIALIZER
#	else
#		define INIT_LOCK(x) init_recursive_mutex(&(x))

static inline void init_recursive_mutex(pthread_mutex_t *x)
{
	pthread_mutexattr_t recursiveAttributes;
	pthread_mutexattr_init(&recursiveAttributes);
	pthread_mutexattr_settype(&recursiveAttributes, PTHREAD_MUTEX_RECURSIVE);
	pthread_mutex_init(x, &recursiveAttributes);
	pthread_mutexattr_destroy(&recursiveAttributes);
}
#	endif

#	define LOCK(x) pthread_mutex_lock(x)
#	define UNLOCK(x) pthread_mutex_unlock(x)
#	define DESTROY_LOCK(x) pthread_mutex_destroy(x)
#endif // WIISTEP
#endif

__attribute__((unused)) static void objc_release_lock(void *x)
{
	mutex_t *lock = *(mutex_t**)x;
	UNLOCK(lock);
}
/**
 * Acquires the lock and automatically releases it at the end of the current
 * scope.
 */
#define LOCK_FOR_SCOPE(lock) \
	__attribute__((cleanup(objc_release_lock)))\
	__attribute__((unused)) mutex_t *lock_pointer = lock;\
	LOCK(lock)

/**
 * The global runtime mutex.
 */
extern mutex_t runtime_mutex;

#define LOCK_RUNTIME() LOCK(&runtime_mutex)
#define UNLOCK_RUNTIME() UNLOCK(&runtime_mutex)
#define LOCK_RUNTIME_FOR_SCOPE() LOCK_FOR_SCOPE(&runtime_mutex)

#endif // __LIBOBJC_LOCK_H_INCLUDED__
