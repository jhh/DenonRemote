// MainZoneController.h
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

#import <Cocoa/Cocoa.h>
#import "DenonRemoteLib.h"
@class SessionManager;

@interface MainZoneController : NSViewController {
@private
    BOOL             _initializing;
    BOOL             _active;
    BOOL             _mute;
    BOOL             _waitingForMasterVolumeEvent;
    NSMutableArray * _inputSources;
    NSArray *        _inputSourceNames;
    NSUInteger       _selectedInputSourceIndex;
    NSUInteger       _inputSourceUsageCount;
    float            _masterVolumeDb;
    float            _volumeIncrement;
}

// Public Methods
- (void) queryMain;


// Actions

- (IBAction) activeStandbyAction:(id)sender;
- (IBAction) muteUnmuteAction:(id)sender;
- (IBAction) changeInputSourceAction:(id)sender;
- (IBAction) changeMasterVolume:(id)sender;
- (IBAction) incrementMasterVolume:(id)sender;
- (IBAction) decrementMasterVolume:(id)sender;
//- (IBAction) openPreferences:(id)sender;
//- (IBAction) reconnectAction:(id)sender;

// Properties


@property (nonatomic, assign, readonly, getter=isInitializing) BOOL initializing;
@property (nonatomic, assign, readonly, getter=isActive) BOOL active;
@property (nonatomic, assign, readonly, getter=isMute) BOOL   mute;
@property (nonatomic, copy,   readonly) NSString *            activeStandbyButtonTitle;
@property (nonatomic, copy,   readonly) NSString *            muteUnmuteButtonTitle;
@property (nonatomic, copy,   readonly) NSArray *             inputSourceNames;
@property (nonatomic, assign, readwrite) NSUInteger           selectedInputSourceIndex;
@property (nonatomic, assign, readwrite) float                masterVolumeDb;

@end
