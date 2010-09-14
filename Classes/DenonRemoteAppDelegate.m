// DenonRemoteAppDelegate.m
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

#import "DenonRemoteAppDelegate.h"

#import "DRSession+Commands.h"
#import "DREvent.h"
#import "DRInputSource.h"
#import "DRDebuggingMacros.h"

#define NUM_4308CI_SOURCES 14

NSString * const DRReceiverAddressKey = @"ReceiverAddress";
//NSString * const DRInputSourcesKey    = @"InputSources";

@interface DenonRemoteAppDelegate () <NSApplicationDelegate, DRSessionDelegate>

// read/write variants of public properties
@property (nonatomic, assign, readwrite, getter=isInitializing) BOOL initializing;
@property (nonatomic, assign, readwrite, getter=isActive) BOOL active;
@property (nonatomic, assign, readwrite, getter=isMute) BOOL   mute;
@property (nonatomic, copy,   readwrite) NSArray * inputSourceNames;

// private properties
@property (nonatomic, readwrite) DRSession * session;
@property (nonatomic, assign, readwrite) NSMutableArray * inputSources;

// forward declarations

@end

@implementation DenonRemoteAppDelegate

@synthesize window = _window;
@synthesize session = _session;

extern NSString * const DRHDPInputSource;
extern NSString * const DRTVCableInputSource;
extern NSString * const DRHDRadioInputSource;
extern NSString * const DRNetUSBInputSource;
extern NSString * const DRDVDInputSource;
extern NSString * const DRSatelliteInputSource;

+ (void)initialize {
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    [defaultValues setValue:@"0.0.0.0" forKey:DRReceiverAddressKey];
    
//    NSMutableDictionary *sources = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                    DRHDPInputSource, DRHDPInputSource,
//                                    DRTVCableInputSource, DRTVCableInputSource,
//                                    DRHDRadioInputSource, DRHDRadioInputSource,
//                                    DRNetUSBInputSource, DRNetUSBInputSource,
//                                    DRDVDInputSource, DRDVDInputSource,
//                                    DRSatelliteInputSource, DRSatelliteInputSource,
//                                    nil];

//    [defaultValues setValue:sources forKey:DRInputSourcesKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (id)init {
    if ((self = [super init])) {
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.inputSources = [NSMutableArray arrayWithCapacity:15];
    }
    return self;
}

#pragma mark -
#pragma mark Application delegate callbacks

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.initializing = YES;
    float delay = 0.0;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    self.session = [[DRSession alloc]
                    initWithHostName:[defaults objectForKey:DRReceiverAddressKey]];
    [self.session setDelegate:self];

    [self.session performSelector:@selector(queryInputSourceNames)
                       withObject:nil afterDelay:delay];
    [self.session performSelector:@selector(queryInputSourceUsage)
                       withObject:nil afterDelay:delay+=1.0];
    DLog(@"delay=%g", delay);
    [self.session performSelector:@selector(queryInputSource) withObject:nil afterDelay:delay+=1.0];
    DLog(@"delay=%g", delay);
    [self.session performSelector:@selector(queryStandby) withObject:nil afterDelay:delay+=0.2];
    DLog(@"delay=%g", delay);
    [self.session performSelector:@selector(queryMute) withObject:nil afterDelay:delay+=0.2];
    DLog(@"delay=%g", delay);
    [self.session performSelector:@selector(queryMasterVolume) withObject:nil afterDelay:delay+=0.2];
    DLog(@"delay=%g", delay);
}

- (void) applicationWillTerminate:(NSNotification *)sender {
    [self.session close];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setValue:@"10.0.1.2" forKey:DRReceiverAddressKey];
//    [defaults setValue:self.inputSources forKey:DRInputSourcesKey];
}

#pragma mark -
#pragma mark Initialization methods

- (void) initializeInputSourceName:(DREvent *)event {
    static NSInteger inputSourceCount = 0;

    DLog(@"%@", [event inputSource]);

    [self.inputSources addObject:[event inputSource]];
    inputSourceCount++;
}

- (void) initializeInputSourceUsage:(DREvent *)event {
    static NSInteger usageCount = 0;
    
    DRInputSource * source = [event inputSource];
    if ([source.name isEqualToString:@"DEL"])
        [self.inputSources removeObject:source];

    usageCount++;
    if (usageCount == NUM_4308CI_SOURCES-1) {
        // all usage events received
        NSMutableArray * result = [NSMutableArray arrayWithCapacity:NUM_4308CI_SOURCES];
        for (DRInputSource * src in self.inputSources) {
            [result addObject:src.name];
        }
        self.inputSourceNames = result;
        self.initializing = NO;
    }
}

#pragma mark -
#pragma mark Session delegate callbacks

- (void) session:(DRSession *)session didReceiveEvent:(DREvent *)event {
    switch (event.eventType) {
        case DenonMuteEvent:
            self.mute = [event boolValue];
            break;
        case DenonInputSourceEvent:
            self.selectedInputSourceIndex = [self.inputSources indexOfObject:[event inputSource]];
            break;
        case DenonMasterVolumeEvent:
            self.masterVolumeDb = [event floatValue];
            break;
        case DenonMasterVolumeMaxEvent:
            break;
        case DenonVideoSelectModeEvent:
            break;
        case DenonPowerEvent:
            self.active = [event boolValue];
            break;
        case DenonInputSourceUsageEvent:
            [self initializeInputSourceUsage:event];
            break;
        case DenonInputSourceNameEvent:
            [self initializeInputSourceName:event];
            break;
        default:
            DLog(@"unexpected eventType: %@ - add a new case to switch statement", event);
    }
}

- (void) session:(DRSession *)session didFailWithError:(NSError *)error {
    DLog(@"%@", error);
}

#pragma mark -
#pragma mark Bound properties

// The user interface uses Cocoa bindings to set itself up based on these
// KVC/KVO compatible properties.

@synthesize initializing = _initializing;

@synthesize active = _active;

+ (NSSet *) keyPathsForValuesAffectingActiveStandbyButtonTitle {
    return [NSSet setWithObject:@"active"];
}

- (NSString *) activeStandbyButtonTitle {
    return self.isActive ? @"Turn Off" : @"Turn On";
}

@synthesize mute = _mute;

+ (NSSet *) keyPathsForValuesAffectingMuteUnmuteButtonTitle {
    return [NSSet setWithObject:@"mute"];
}

- (NSString *) muteUnmuteButtonTitle {
    return self.isMute ? @"Mute Off" : @"Mute";
}

@synthesize inputSources = _inputSources;
@synthesize inputSourceNames = _inputSourceNames;
@synthesize selectedInputSourceIndex = _selectedInputSourceIndex;
@synthesize masterVolumeDb = _masterVolumeDb;


#pragma mark -
#pragma mark Actions

- (IBAction) activeStandbyAction:(id)sender {
    if (self.isActive) {
        [self.session sendPower:DROnState];
    } else {
        [self.session sendPower:DROffState];
    }
}

- (IBAction) muteUnmuteAction:(id)sender {
    if (self.isMute) {
        [self.session sendMute:DROnState];
    } else {
        [self.session sendMute:DROffState];
    }
}

- (IBAction) changeInputSourceAction:(id)sender {
    [self.session sendInputSource:[self.inputSources objectAtIndex:self.selectedInputSourceIndex]];
}

- (IBAction) changeMasterVolume:(id)sender {
    [self.session sendMasterVolume:self.masterVolumeDb];
}

- (IBAction) incrementMasterVolume:(id)sender {
    if (self.masterVolumeDb >= 18.0) {
        self.masterVolumeDb = 18.0;
        return;
    }
    [self.session sendMasterVolume:self.masterVolumeDb+=1.0];
}

- (IBAction) decrementMasterVolume:(id)sender {
    if (self.masterVolumeDb <= -80.0) {
        self.masterVolumeDb = -80.0;
        return;
    }
    [self.session sendMasterVolume:self.masterVolumeDb-=1.0];    
}

@end

