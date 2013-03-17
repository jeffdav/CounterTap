//
//  CTAppDelegate.m
//  CounterTap
//
//  Created by Jeff Davis on 3/16/13.
//  Copyright (c) 2013 JorfSoft. All rights reserved.
//

#import "CTAppDelegate.h"

#import "CTCounterTableViewController.h"

@implementation CTAppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    UINavigationController* rootController = [[[UINavigationController alloc] init] autorelease];
    self.window.rootViewController = rootController;

    CTCounterTableViewController* counterTableViewController = [[[CTCounterTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    [rootController pushViewController:counterTableViewController animated:NO];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
