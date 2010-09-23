// PreferencesWindowController.m
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

#import "PreferencesWindowController.h"
#import "DRDebuggingMacros.h"
#import "AsyncSocket.h"

@interface PreferencesWindowController ()

// read/write variants of public properties
@property(nonatomic, assign, readwrite) NSImage * receiverStatusImage;
@property(nonatomic, assign, readwrite) NSString * receiverStatusMessage;

// forward declaratons
- (void) updateReceiverAddressStatus;

@end


@implementation PreferencesWindowController

- (id)init {
    if ((self = [super initWithWindowNibName:@"PreferencesWindow"])) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void) windowDidLoad {
    [super windowDidLoad];
    self.receiverAddress = [_defaults valueForKey:@"ReceiverAddress"];
    self.receiverStatusImage = [NSImage imageNamed:NSImageNameStatusNone];
}

#pragma mark -
#pragma mark Properties

@synthesize receiverAddress = _receiverAddress;

- (void) setReceiverAddress:(NSString *)receiverAddress {
    _receiverAddress = [receiverAddress copy];
    [_defaults setValue:self.receiverAddress forKey:@"ReceiverAddress"];
    [self updateReceiverAddressStatus];
}

@synthesize receiverStatusImage = _receiverStatusImage;
@synthesize receiverStatusMessage = _receiverStatusMessage;

#pragma mark -
#pragma mark Other Methods

- (void) updateReceiverAddressStatus {
//    AsyncSocket * sock = [[AsyncSocket alloc] init];
//    UInt16 port = [_defaults integerForKey:@"ReceiverPort"];
//    NSTimeInterval timeout = [_defaults floatForKey:@"ReceiverStatusTimeout"];
//    NSError * error;
//
//    [sock connectToHost:self.receiverAddress onPort:port withTimeout:timeout error:&error];
//    self.receiverStatusImage = [NSImage imageNamed:NSImageNameStatusAvailable];
}

@end
