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
#import "PreferencesController.h"
#import "MainWindowController.h"
#import "SessionManager.h"

@interface DenonRemoteAppDelegate () <NSApplicationDelegate>

//// read/write variants of public properties
//@property (nonatomic, assign, readwrite, getter=isInitializing) BOOL initializing;
//@property (nonatomic, assign, readwrite, getter=isActive) BOOL active;
//@property (nonatomic, assign, readwrite, getter=isMute) BOOL   mute;

// private properties
//@property (nonatomic, assign, readwrite) DRSession * session;

// forward declarations
//- (void) disconnectIfConnected;

@end

@implementation DenonRemoteAppDelegate

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

- (void) awakeFromNib {
    // Connect to receiver
    [[SessionManager sharedManager] connect];

    _mainWindowController = [[MainWindowController alloc] init];

    [[_mainWindowController window] makeMainWindow];
    [[_mainWindowController window] makeKeyAndOrderFront:self];

	// the app controller wants to know if the user closes the main window by hitting cmd-w or with the close button on the window
	// it registers to get notified of this event
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMainWindowWillClose:) name:NSWindowWillCloseNotification object:[_mainWindowController window]];
    

}

#pragma mark -
#pragma mark Application delegate callbacks

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
}


- (void) applicationWillTerminate:(NSNotification *)sender {
    [[[SessionManager sharedManager] session] close];
}


#pragma mark -
#pragma mark Private methods


//- (void) disconnectIfConnected {
//    if (self.session) {
//        DLog(@"Session (%@) exists, closing before reopening", self.session);
//        [self.session close];
//        self.session = nil;
//    }
//}



#pragma mark -
#pragma mark Initialization methods



//- (IBAction) openPreferences:(id)sender {
//    NSWindow * window = [_preferencesController window];
//
//    if (![window isVisible])
//        [window center];
//
//    [window makeKeyAndOrderFront:self];
//}

- (IBAction) reconnectAction:(id)sender {
//    [self disconnectIfConnected];
    // connection refused error if connect not delayed - 0.2 value is emperical
    [self performSelector:@selector(connect) withObject:nil afterDelay:0.2];
}

@end

