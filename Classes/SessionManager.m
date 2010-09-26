// SessionManager.m
// DenonRemote
//
// Copyright 2010 Jeffrey Hutchison
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SessionManager.h"

NSString * const DREventNotification = @"DREventNotification";


@implementation SessionManager


+ (SessionManager *) sharedManager {
    static SessionManager * manager = nil;
    if (!manager)
        manager = [[self alloc] init];
    return manager;
}


- (id)init {
    if ((self = [super init])) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}


#pragma mark -
#pragma mark Public Methods


- (void) connect {
    _session = [[DRSession alloc] initWithHostName:[_defaults valueForKey:@"ReceiverAddress"]];
    _session.delegate = self;
    [self.session queryStandby];
}


#pragma mark -
#pragma mark DRSession Delegates


- (void) session:(DRSession *)session didReceiveEvent:(DREvent *)event {
    _event = event;
    [[NSNotificationCenter defaultCenter] postNotificationName:DREventNotification object:self];
}


- (void) session:(DRSession *)session didFailWithError:(NSError *)error {
    DLog(@"%@", error);
}


#pragma mark -
#pragma mark Properties
@synthesize session = _session;
@synthesize defaults = _defaults;
@synthesize event = _event;

@end
