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
#import "PreferencesWindowController.h"

#import "DRSession+Commands.h"
#import "DREvent.h"
#import "DRInputSource.h"
#import "DRDebuggingMacros.h"

#define NUM_4308CI_SOURCES 14

@interface DenonRemoteAppDelegate () <NSApplicationDelegate, DRSessionDelegate>

// read/write variants of public properties
@property (nonatomic, assign, readwrite, getter=isInitializing) BOOL initializing;
@property (nonatomic, assign, readwrite, getter=isActive) BOOL active;
@property (nonatomic, assign, readwrite, getter=isMute) BOOL   mute;
@property (nonatomic, copy,   readwrite) NSArray * inputSourceNames;

// private properties
@property (nonatomic, assign, readwrite) DRSession * session;
@property (nonatomic, assign, readwrite) NSMutableArray * inputSources;

// forward declarations
- (void) disconnectIfConnected;
- (void) connect;
- (void) queryMain;

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

+ (void) initialize {
    NSDictionary * defaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
}

- (id) init {
    if ((self = [super init])) {
        _defaults = [NSUserDefaults standardUserDefaults];
        _volumeIncrement = [_defaults floatForKey:@"VolumeIncrement"];
        self.inputSources = [NSMutableArray arrayWithCapacity:15];
        _preferencesWindowController = [[PreferencesWindowController alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark Application delegate callbacks

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
//    [[NSApp mainMenu] addItem:[[FScriptMenuItem alloc] init]];
    [self connect];
    [self queryMain];
}


- (void) applicationWillTerminate:(NSNotification *)sender {
    [self.session close];
}


#pragma mark -
#pragma mark Private methods


- (void) disconnectIfConnected {
    if (self.session) {
        DLog(@"Session (%@) exists, closing before reopening", self.session);
        [self.session close];
        self.session = nil;
    }
}


- (void) connect {
    self.session = [[DRSession alloc]
                    initWithHostName:[_defaults valueForKey:@"ReceiverAddress"]];
    self.session.delegate = self;
    DLog(@"self = %@; session = %@; delegate = %@", self, self.session, self.session.delegate);
    _waitingForMasterVolumeEvent = NO;
}


- (void) queryMain {

    // series of commands are sent from this method - schedule each command on run loop
    // with delays between each to allow receiver to respond.
    float sd = [_defaults floatForKey:@"CommandSendDelay"];
    float lsd = sd * 5.0; // long send delay
    float delay = 0.0; // accumulated delay

    // turn on initializing spinner while querying status
    self.initializing = YES;

    // populate input source drop down
    [self.session performSelector:@selector(queryInputSourceNames)
                       withObject:nil afterDelay:delay];

    // this command returns list of deleted/used input sources as series of events
    // keep track of events received to turn off spinner and enable input
    // source drop down
    // long delay - multiple events returned from previous queryInputSourceNames
    _inputSourceUsageCount = 0;
    [self.session performSelector:@selector(queryInputSourceUsage)
                       withObject:nil afterDelay:delay+=lsd];

    // long delay - multiple events returned from previous queryInputSourceUsage
    [self.session performSelector:@selector(queryInputSource) withObject:nil afterDelay:delay+=lsd];

    // normal delay - single event from previous queryInputSource and the following
    [self.session performSelector:@selector(queryStandby) withObject:nil afterDelay:delay+=sd];
    [self.session performSelector:@selector(queryMute) withObject:nil afterDelay:delay+=sd];
    [self.session performSelector:@selector(queryMasterVolume) withObject:nil afterDelay:delay+=sd];
}


#pragma mark -
#pragma mark Initialization methods


- (void) initializeInputSourceUsage:(DREvent *)event {
    
    DRInputSource * source = [event inputSource];
    if ([source.name isEqualToString:@"DEL"])
        [self.inputSources removeObject:source];

    _inputSourceUsageCount++;
    if (_inputSourceUsageCount == NUM_4308CI_SOURCES-1) {
        // all usage events received
        NSMutableArray * result = [NSMutableArray arrayWithCapacity:NUM_4308CI_SOURCES];
        for (DRInputSource * src in self.inputSources) {
            [result addObject:src.name];
        }
        self.inputSourceNames = result;

        // all done, turn off initializing spinner that was turned on in queryMain
        self.initializing = NO;
    }
}

#pragma mark -
#pragma mark Session delegate callbacks

- (void) session:(DRSession *)session didReceiveEvent:(DREvent *)event {
    DLog(@"%@", event);
    switch (event.eventType) {
        case DenonMuteEvent:
            self.mute = [event boolValue];
            break;
        case DenonInputSourceEvent:
            self.selectedInputSourceIndex = [self.inputSources indexOfObject:[event inputSource]];
            break;
        case DenonMasterVolumeEvent:
            self.masterVolumeDb = [event floatValue];
            // increment/decrement a no-op until previous volume command responds
            _waitingForMasterVolumeEvent = NO;
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
            [self.inputSources addObject:[event inputSource]];
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
    // don't increment past the maximum possible volume
    if (self.masterVolumeDb >= 18.0) {
        self.masterVolumeDb = 18.0;
        return;
    }

    // don't send another command to increment volume if we have a previous
    // volume command pending, prevents the slider from jumping backwards
    // when holding down keyboard shortcut
    if (!_waitingForMasterVolumeEvent) {
        [self.session sendMasterVolume:self.masterVolumeDb+=_volumeIncrement];
        _waitingForMasterVolumeEvent = YES;
    }
}

- (IBAction) decrementMasterVolume:(id)sender {
    // don't decrement below the minimum possible volume
    if (self.masterVolumeDb <= -80.0) {
        self.masterVolumeDb = -80.0;
        return;
    }

    // don't send another command to decrement volume if we have a previous
    // volume command pending, prevents the slider from jumping backwards
    // when holding down keyboard shortcut
    if (!_waitingForMasterVolumeEvent) {
        [self.session sendMasterVolume:self.masterVolumeDb-=_volumeIncrement];
        _waitingForMasterVolumeEvent = YES;
    }
}

- (IBAction) openPreferences:(id)sender {
    NSWindow * window = [_preferencesWindowController window];

    if (![window isVisible])
        [window center];

    [window makeKeyAndOrderFront:self];
}

- (IBAction) reconnectAction:(id)sender {
    [self disconnectIfConnected];
    // connection refused error if connect not delayed - 0.2 value is emperical
    [self performSelector:@selector(connect) withObject:nil afterDelay:0.2];
}

@end

