// ConfigController.m
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

#import "ConfigController.h"
#import "MainWindowController.h"
#import "ReceiverConnectionChecker.h"
#import "AsyncSocket.h"

@implementation ConfigController

- (id)init {
    if ((self = [super initWithNibName:@"ConfigView" bundle:nil])) {
    }
    return self;
}

- (void) awakeFromNib {
    self.receiverAddress = [[NSUserDefaults standardUserDefaults] valueForKey:@"ReceiverAddress"];    
}


- (IBAction) doneAction:(id)sender {
    NSView * view = [self view];
    NSWindow * window = [view window];
    MainWindowController * windowController = (MainWindowController *)[window delegate];
    [windowController doneWithConfigView];
}


-(void) receiverConnectionCheckerDidFinish:(ReceiverConnectionChecker *)checker {

    [self.probeProgressIndicator stopAnimation:nil];

    switch (checker.status) {
        case ReceiverConnectionChecking:
            DLog(@"Checker returned ReceiverConnectionChecking");
            self.receiverStatusText = @"Checking connection...";
            self.receiverStatusImage = [NSImage imageNamed:NSImageNameStatusNone];
            break;
        case ReceiverConnectionSuccess:
            DLog(@"Checker returned ReceiverConnectionSuccess");
            self.receiverStatusText = @"Connection succeeded";
            self.receiverStatusImage = [NSImage imageNamed:NSImageNameStatusAvailable];
            break;
        case ReceiverConnectionFail:
            DLog(@"Checker returned ReceiverConnectionFail");
            self.receiverStatusText = @"Connection failed";
            self.receiverStatusImage = [NSImage imageNamed:NSImageNameStatusUnavailable];
            break;
        case ReceiverConnectionError:
            DLog(@"Checker returned ReceiverConnectionError");

            if ([[checker.error domain] isEqualToString:NSPOSIXErrorDomain]) {
                if ([checker.error code] == ECONNREFUSED)
                    self.receiverStatusText = @"Connection refused";
            } else if ([[checker.error domain] isEqualToString:AsyncSocketErrorDomain]) {
                if ([checker.error code] == AsyncSocketConnectTimeoutError)
                    self.receiverStatusText = @"Connection timeout";
            } else {
                self.receiverStatusText = @"Connection error";
            }
            
            self.receiverStatusImage = [NSImage imageNamed:NSImageNameStatusUnavailable];
            break;
        default:
            ALog(@"Checker returned unrecognized status: %d", checker.status);
    }
}

#pragma mark -
#pragma mark NSTextFieldDelegate Methods

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    _previousText = [fieldEditor string];
    DLog(@"%@", _previousText);
    return YES;
}


#pragma mark -
#pragma mark Bound Properties
@synthesize receiverAddress = _receiverAddress;
@synthesize probeProgressIndicator = _probeProgressIndicator;
@synthesize receiverStatusImage = _receiverStatusImage;
@synthesize receiverStatusText = _receiverStatusText;

- (void) setReceiverAddress:(NSString *)receiverAddress {
    
    if ( ![receiverAddress isEqualToString:_receiverAddress] ) {
        _receiverAddress = receiverAddress;
        [[NSUserDefaults standardUserDefaults] setValue:receiverAddress forKey:@"ReceiverAddress"];        
    }

    [self.probeProgressIndicator startAnimation:nil];
    self.receiverStatusText = @"Checking connection...";
    self.receiverStatusImage = nil;

    if (_receiverConnectionChecker) {
        [_receiverConnectionChecker cancelProbe];
    }
    _receiverConnectionChecker = [[ReceiverConnectionChecker alloc] initForAddress:self.receiverAddress delay:YES withDelegate:self];
}

@end
