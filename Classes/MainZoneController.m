// MainZoneController.m
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

#import "MainZoneController.h"
#import "SessionManager.h"

#define NUM_4308CI_SOURCES 14


@interface MainZoneController ()

// read/write variants of public properties
@property (nonatomic, assign, readwrite, getter=isInitializing) BOOL initializing;
@property (nonatomic, assign, readwrite, getter=isActive) BOOL active;
@property (nonatomic, assign, readwrite, getter=isMute) BOOL   mute;
@property (nonatomic, copy,   readwrite) NSArray * inputSourceNames;
@property (nonatomic, assign, readwrite) NSMutableArray * inputSources;

// forward declarations
- (void) initializeInputSourceUsage:(DREvent *)event;

@end


@implementation MainZoneController


- (id)init {
    if ((self = [super initWithNibName:@"MainZoneView" bundle:nil])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventReceived:) name:DREventNotification object:nil];
         self.inputSources = [NSMutableArray arrayWithCapacity:NUM_4308CI_SOURCES];
        _volumeIncrement = [[NSUserDefaults standardUserDefaults] floatForKey:@"VolumeIncrement"];
    }
    return self;
}

- (void) awakeFromNib {
    [self queryMain];
}


- (void) eventReceived:(NSNotification *)notification {
    SessionManager * manager = (SessionManager *) [notification object];
    DLog(@"%@: %@", manager, manager.event);
    switch (manager.event.eventType) {
        case DenonMuteEvent:
            self.mute = [manager.event boolValue];
            break;
        case DenonInputSourceEvent:
            self.selectedInputSourceIndex = [self.inputSources indexOfObject:[manager.event inputSource]];
            break;
        case DenonMasterVolumeEvent:
            self.masterVolumeDb = [manager.event floatValue];
            // increment/decrement a no-op until previous volume command responds
            _waitingForMasterVolumeEvent = NO;
            break;
        case DenonMasterVolumeMaxEvent:
            break;
        case DenonVideoSelectModeEvent:
            break;
        case DenonPowerEvent:
            self.active = [manager.event boolValue];
            break;
        case DenonInputSourceUsageEvent:
            [self initializeInputSourceUsage:manager.event];
            break;
        case DenonInputSourceNameEvent:
            [self.inputSources addObject:[manager.event inputSource]];
//            DLog(@"ADDED %@; INPUTSOURCES NOW = %@", [manager.event inputSource], self.inputSources);
            break;
        default:
            DLog(@"unexpected eventType: %@ - add a new case to switch statement", manager.event);
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) queryMain {
    
    // series of commands are sent from this method - schedule each command on run loop
    // with delays between each to allow receiver to respond.
    float sd = [[NSUserDefaults standardUserDefaults] floatForKey:@"CommandSendDelay"];
    float lsd = sd * 5.0; // long send delay
    float delay = 0.0; // accumulated delay

    DRSession * session = [[SessionManager sharedManager] session];

    // turn on initializing spinner while querying status
    self.initializing = YES;
    // populate input source drop down
    [session performSelector:@selector(queryInputSourceNames) withObject:nil afterDelay:delay];
    
    // this command returns list of deleted/used input sources as series of events
    // keep track of events received to turn off spinner and enable input
    // source drop down
    // long delay - multiple events returned from previous queryInputSourceNames
    _inputSourceUsageCount = 0;
    [session performSelector:@selector(queryInputSourceUsage) withObject:nil afterDelay:delay+=lsd];
    
    // long delay - multiple events returned from previous queryInputSourceUsage
    [session performSelector:@selector(queryInputSource) withObject:nil afterDelay:delay+=lsd];
    
    // normal delay - single event from previous queryInputSource and the following
    [session performSelector:@selector(queryStandby) withObject:nil afterDelay:delay+=sd];
    [session performSelector:@selector(queryMute) withObject:nil afterDelay:delay+=sd];
    [session performSelector:@selector(queryMasterVolume) withObject:nil afterDelay:delay+=sd];
}

#pragma mark -
#pragma mark Private Methods

- (void) initializeInputSourceUsage:(DREvent *)event {
    DLog(@"%@", event);
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
    DRSession * session = [[SessionManager sharedManager] session];
    [session sendPower:self.isActive ? DROnState : DROffState];
}


- (IBAction) muteUnmuteAction:(id)sender {
    DRSession * session = [[SessionManager sharedManager] session];
    [session sendMute:self.isMute ? DROnState : DROffState];
}


- (IBAction) changeInputSourceAction:(id)sender {
    DRSession * session = [[SessionManager sharedManager] session];
    [session sendInputSource:[self.inputSources objectAtIndex:self.selectedInputSourceIndex]];
}


- (IBAction) changeMasterVolume:(id)sender {
    DRSession * session = [[SessionManager sharedManager] session];
    [session sendMasterVolume:self.masterVolumeDb];
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
        DRSession * session = [[SessionManager sharedManager] session];
        [session sendMasterVolume:self.masterVolumeDb+=_volumeIncrement];
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
        DRSession * session = [[SessionManager sharedManager] session];
        [session sendMasterVolume:self.masterVolumeDb-=_volumeIncrement];
        _waitingForMasterVolumeEvent = YES;
    }
}

@end
