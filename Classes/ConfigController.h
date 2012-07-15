// ConfigController.h
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
@class ReceiverConnectionChecker;

@interface ConfigController : NSViewController <NSTextFieldDelegate> {


@private
    NSString * _previousText;
    NSString * _receiverAddress;
    NSProgressIndicator * _probeProgressIndicator;
    NSImage * _receiverStatusImage;
    NSString * _receiverStatusText;
    ReceiverConnectionChecker * _receiverConnectionChecker;
}

@property (nonatomic, copy, readwrite) NSString * receiverAddress;
@property (nonatomic, readwrite) IBOutlet NSProgressIndicator * probeProgressIndicator;
@property (nonatomic, readwrite) NSImage * receiverStatusImage;
@property (nonatomic, readwrite) NSString * receiverStatusText;

// Actions

- (IBAction) doneAction:(id)sender;

@end
