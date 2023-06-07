//
//  CDVAppUpdate
//
//  Created by Austen Zeh <developerDawg@gmail.com> on 2020-03-16
//
#import "CDVAppUpdate.h"
#import <objc/runtime.h>
#import <Cordova/CDVViewController.h>

static NSString *const TAG = @"CDVAppUpdate";

@implementation CDVAppUpdate

-(void) needsUpdate:(CDVInvokedUrlCommand*)command
{
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString* appID = infoDictionary[@"CFBundleIdentifier"];
    NSString* force_api = nil;
    NSString* force_key = nil;
    if ([command.arguments count] > 0) {
        force_api = [command.arguments objectAtIndex:0];
        force_key = [command.arguments objectAtIndex:1];
    }

    BOOL update_avail = NO;
    BOOL update_force = NO;
    NSMutableDictionary *resultObj = [[NSMutableDictionary alloc]initWithCapacity:10];

    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", appID]];
    NSData* data = [NSData dataWithContentsOfURL:url];
    if (data == nil) {
        NSLog(@"%@ AppUpdate returns nil data, e.g no data connection", TAG);
    } else {
        NSDictionary* lookup = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        NSLog(@"%@ Checking for app update", TAG);
        if ([lookup[@"resultCount"] integerValue] == 1) {
            NSString* appStoreVersion = lookup[@"results"][0][@"version"];
            NSString* currentVersion = infoDictionary[@"CFBundleShortVersionString"];

            // Support for version number of format #.#.# (one digit per section) e.g.
            // 1.0.0, 1.0.1, ..., 1.0.9, 1.1.0, 1.1.1, ...
            // 1.9.0, 1.9.1, ..., 1.9.9, 2.0.0, ... 
            // Limit to 999 versions, ~ 1 version/week -> 20 years life-time per app

            if ([currentVersion compare:appStoreVersion] == NSOrderedAscending) {
                NSLog(@"%@ Need to update [%@ > %@]", TAG, appStoreVersion, currentVersion);
                if ([force_api length] > 0) {
                    NSURL* force_url = [NSURL URLWithString:[NSString stringWithFormat:force_api]];
                    NSData* force_data = [NSData dataWithContentsOfURL:force_url];
                    NSDictionary* force_lookup = [NSJSONSerialization JSONObjectWithData:force_data options:0 error:nil];
                    update_force = [force_lookup objectForKey:force_key];
                    for (id key in force_lookup) {
                        [resultObj setObject:[force_lookup objectForKey:key] forKey:key];
                    }
                }
                NSLog(@"%@ Force Update: %i", TAG, update_force);
                update_avail = YES;
            }
        }
    }

    [resultObj setObject:[NSNumber numberWithBool:update_avail] forKey:@"update_available"];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultObj];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

@end