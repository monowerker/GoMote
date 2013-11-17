//
//  GMAppDelegate.m
//  GoMote
//
//  Created by Daniel Ericsson on 2013-11-15.
//  Copyright (c) 2013 MONOWERKS. All rights reserved.
//

#import "GMAppDelegate.h"
// -- Controllers
#import "GMViewController.h"

@implementation GMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[GMViewController alloc] initWithNibName:nil bundle:nil];
	[self.window makeKeyAndVisible];
    
    return YES;
}

@end
