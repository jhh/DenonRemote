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


@implementation MainWindowController

- (id)init {
    if ((self = [super initWithWindowNibName:@"MainWindow"])) {
    }
    return self;
}

- (MainZoneController *)mainZoneController {
    if (_mainZoneController == nil)
        _mainZoneController = [[MainZoneController alloc] init];
    return _mainZoneController;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSView * contentView = [[self window] contentView];
    NSView * mainZoneView = [[self mainZoneController] view];
    
    // Remove the current view
    for (NSView * view in [contentView subviews])
        [view removeFromSuperview];
    
    [contentView addSubview:mainZoneView];

    // patch the detail view into the responder chain
	NSResponder * aNextResponder = [self nextResponder];
	[self setNextResponder:_mainZoneController];
	[_mainZoneController setNextResponder:aNextResponder];


}


@end
