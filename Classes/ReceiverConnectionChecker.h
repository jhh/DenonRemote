// ReceiverConnectionChecker.h
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
@class AsyncSocket;

typedef enum {
    ReceiverConnectionChecking,
    ReceiverConnectionSuccess,
    ReceiverConnectionFail,
    ReceiverConnectionError,
} ReceiverConnectionCheckerStatus;


@interface ReceiverConnectionChecker : NSObject {
@private
    AsyncSocket * _socket;
    NSTimeInterval _socketTimeout;

    id _delegate;
    ReceiverConnectionCheckerStatus _status;
    NSError * _error;
    
    NSTimer * _timer;
}

// Properties

@property (nonatomic, readonly) ReceiverConnectionCheckerStatus status;
@property (nonatomic, readonly) NSError * error;

// Public Methods

- (id) initForAddress:(NSString *)address delay:(BOOL)delay withDelegate:(id) delegate;

- (void) cancelProbe;

@end
