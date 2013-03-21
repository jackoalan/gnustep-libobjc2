#include <time.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdarg.h>
#include "objc/runtime.h"

#include <gccore.h>
#include <unistd.h>

#define SLEEP() sleep(1)

static void
wii_init ()
{
	
	void *xfb = NULL;
	GXRModeObj *rmode = NULL;
	
	// Initialise the video system
	VIDEO_Init();
	
	// This function initialises the attached controllers
	//WPAD_Init();
	
	// Obtain the preferred video mode from the system
	// This will correspond to the settings in the Wii menu
	rmode = VIDEO_GetPreferredMode(NULL);
	
	// Allocate memory for the display in the uncached region
	xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));
	
	// Initialise the console, required for printf
	console_init(xfb,20,20,rmode->fbWidth,rmode->xfbHeight,rmode->fbWidth*VI_DISPLAY_PIX_SZ);
	
	// Set up the video registers with the chosen mode
	VIDEO_Configure(rmode);
	
	// Tell the video hardware where our display memory is
	VIDEO_SetNextFramebuffer(xfb);
	
	// Make the display visible
	VIDEO_SetBlack(FALSE);
	
	// Flush the video register changes to the hardware
	VIDEO_Flush();
	
	// Wait for Video setup to complete
	VIDEO_WaitVSync();
	if(rmode->viTVMode&VI_NON_INTERLACE) VIDEO_WaitVSync();
	
	
	// The console understands VT terminal escape codes
	// This positions the cursor on row 2, column 0
	// we can use variables for this with format codes too
	// e.g. printf ("\x1b[%d;%dH", row, column );
	printf("\x1b[2;0H");
	
}

//#undef assert
//#define assert(x) if (!(x)) { printf("Failed %d\n", __LINE__); }

id objc_msgSend(id, SEL, ...);

typedef struct { int a,b,c,d,e; } s;
@interface Fake
- (int)izero;
- (float)fzero;
- (double)dzero;
//- (long double)ldzero;
@end

Class TestCls;
#ifdef __has_attribute
#if __has_attribute(objc_root_class)
__attribute__((objc_root_class))
#endif
#endif
@interface Test { id isa; }@end
@implementation Test 
- foo
{
	assert((id)1 == self);
	assert(strcmp("foo", sel_getName(_cmd)) == 0);
	return (id)0x42;
}
+ foo
{
	assert(TestCls == self);
	assert(strcmp("foo", sel_getName(_cmd)) == 0);
	return (id)0x42;
}
+ (s)sret
{
	assert(TestCls == self);
	assert(strcmp("sret", sel_getName(_cmd)) == 0);
	s st = {1,2,3,4,5};
	return st;
}
- (s)sret
{
	assert((id)3 == self);
	assert(strcmp("sret", sel_getName(_cmd)) == 0);
	s st = {1,2,3,4,5};
	return st;
}
+ (void)printf: (const char*)str, ...
{
	va_list ap;
	char *s;

	va_start(ap, str);

	vasprintf(&s, str, ap);
	va_end(ap);
	printf("String: '%s'\n", s);
	sleep(5);
	assert(strcmp(s, "Format string 42 42.000000\n") ==0);
}
+ (void)initialize
{
	[self printf: "Format %s %d %f%c", "string", 42, 42.0, '\n'];
	@throw self;
}
+ nothing { return 0; }
@end
#define BENCHMARK 1
int main(void)
{
	void* mem1_arena_at_init = SYS_GetArena1Lo();
	wii_init();
	size_t mem1_arena_diff_after_wii_init = SYS_GetArena1Lo()-mem1_arena_at_init;
	printf("Branching to load routine... Platform Overhead: %u\n", mem1_arena_diff_after_wii_init);
	SLEEP();
	__asm__ __volatile__ ("bl .objc_load_function");
	size_t mem1_arena_diff_after_objc_init = SYS_GetArena1Lo()-mem1_arena_at_init;
	DCFlushRange(mem1_arena_at_init, ((mem1_arena_diff_after_objc_init>>5)<<5)+32);
	printf("Obj-C on Wii initialised... Runtime Overhead: %u\n", mem1_arena_diff_after_objc_init-mem1_arena_diff_after_wii_init);
	SLEEP();
	//id fake = nil;
	//id something = objc_msgSend(fake, @selector(printf:));
	//printf("Return val: %x\n", something);
	TestCls = objc_getClass("Test");
	int exceptionThrown = 0;
	printf("ABOUT TO ELLO\n");
	[TestCls printf:"ELLO!\n"];
	printf("DID IT ELLO?\n");
	@try {
		objc_msgSend(TestCls, @selector(foo));
	} @catch (id e)
	{
		assert((TestCls == e) && "Exceptions propagate out of +initialize");
		exceptionThrown = 1;
	}
	assert(exceptionThrown && "An exception was thrown");
	/*
	assert((id)0x42 == objc_msgSend(TestCls, @selector(foo)));
	objc_msgSend(TestCls, @selector(nothing));
	objc_msgSend(TestCls, @selector(missing));
	assert(0 == objc_msgSend(0, @selector(nothing)));
	id a = objc_msgSend(objc_getClass("Test"), @selector(foo));
	assert((id)0x42 == a);
	a = objc_msgSend(TestCls, @selector(foo));
	assert((id)0x42 == a);
	assert(objc_registerSmallObjectClass_np(objc_getClass("Test"), 1));
	a = objc_msgSend((id)01, @selector(foo));
	assert((id)0x42 == a);
	s ret = ((s(*)(id, SEL))objc_msgSend_stret)(TestCls, @selector(sret));
	assert(ret.a == 1);
	assert(ret.b == 2);
	assert(ret.c == 3);
	assert(ret.d == 4);
	assert(ret.e == 5);
	if (sizeof(id) == 8)
	{
		assert(objc_registerSmallObjectClass_np(objc_getClass("Test"), 3));
		ret = ((s(*)(id, SEL))objc_msgSend_stret)((id)3, @selector(sret));
		assert(ret.a == 1);
		assert(ret.b == 2);
		assert(ret.c == 3);
		assert(ret.d == 4);
		assert(ret.e == 5);
	}
	Fake *f = nil;
	assert(0 == [f izero]);
	assert(0 == [f dzero]);
	//assert(0 == [f ldzero]);
	assert(0 == [f fzero]);
#ifdef BENCHMARK
	clock_t c1, c2;
	c1 = clock();
	for (int i=0 ; i<100000000 ; i++)
	{
		[TestCls nothing];
	}
	c2 = clock();
	printf("Traditional message send took %f seconds. \n", 
		((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);
	c1 = clock();
	for (int i=0 ; i<100000000 ; i++)
	{
		objc_msgSend(TestCls, @selector(nothing));
	}
	c2 = clock();
	printf("objc_msgSend() message send took %f seconds. \n", 
		((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);
	IMP nothing = objc_msg_lookup(TestCls, @selector(nothing));
	c1 = clock();
	for (int i=0 ; i<100000000 ; i++)
	{
		nothing(TestCls, @selector(nothing));
	}
	c2 = clock();
	printf("Direct IMP call took %f seconds. \n", 
		((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);
#endif
	 */
	printf("Finished\n");
	sleep(5);
	return 0;
}
