//
//  MWLog.m
//
//  Created by monowerker on 2013-09-19.
//

#import "MWLog.h"

static void initClassList(void);
static NSMutableSet *enabledClasses = nil;
static BOOL classFilterEnabled = NO;

void MWDebug(const char *fileName, int lineNumber, Class class, NSString *fmt, ...) {
    if (classFilterEnabled) {
        if (![enabledClasses containsObject:class]) {
            return;
        }
    }
    
	va_list args;
	va_start(args, fmt);
	
	NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
	NSString *filePath = [[NSString alloc] initWithUTF8String:fileName];
	
	NSLog(@"[%@:%d] %@", [filePath lastPathComponent], lineNumber, msg);
	
	va_end(args);
}

void MWDebugClassFilter(BOOL enabled) {
    classFilterEnabled = enabled;
}

void MWDebugAddClass(Class class) {
    initClassList();
    [enabledClasses addObject:class];
}

void MWDebugRemoveClass(Class class) {
    initClassList();
    [enabledClasses removeObject:class];
}

static void initClassList() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        enabledClasses = [[NSMutableSet alloc] init];
    });
}