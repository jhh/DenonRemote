// MainWindowController.m
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

#import "MainWindowController.h"
#import "MainZoneController.h"
#import "ConfigController.h"
#import "SessionManager.h"

@interface MainWindowController ()
- (MainZoneController *) mainZoneController;
- (ConfigController *) configController;
- (void) loadView:(NSViewController *)viewController;
- (BOOL) needsConfiguration;

@end

@implementation MainWindowController

- (id)init {
    if ((self = [super initWithWindowNibName:@"MainWindow"])) {
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    if ([self needsConfiguration]) {
        [self loadView:[self configController]];
    } else {
        [self loadView:[self mainZoneController]];
    }

    // patch the detail view into the responder chain
	NSResponder * aNextResponder = [self nextResponder];
	[self setNextResponder:[self mainZoneController]];
	[[self mainZoneController] setNextResponder:aNextResponder];

}

#pragma mark -
#pragma mark Configuration View

- (IBAction) showConfigView:(id)sender {
    [[[SessionManager sharedManager] session] close];
    [self loadView:[self configController]];
}

- (void) doneWithConfigView {
    [[SessionManager sharedManager] connect];
    [self loadView:[self mainZoneController]];
}


#pragma mark -
#pragma mark Private Methods

- (BOOL) needsConfiguration {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults valueForKey:@"ReceiverAddress"] isEqualToString:@"0.0.0.0" ];
}


- (void) loadView:(NSViewController *)viewController {
    NSView * contentView = [[self window] contentView];
    NSView * newSubView = [viewController view];
    
    // Remove the current view
    for (NSView * view in [contentView subviews])
        [view removeFromSuperview];
    
    [contentView addSubview:newSubView];

}


- (MainZoneController *)mainZoneController {
    if (_mainZoneController == nil)
        _mainZoneController = [[MainZoneController alloc] init];
    return _mainZoneController;
}

- (ConfigController *)configController {
    if (_configController == nil)
        _configController = [[ConfigController alloc] init];
    return _configController;
}

@end
