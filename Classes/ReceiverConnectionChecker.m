// ReceiverConnectionChecker.m
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

#import "ReceiverConnectionChecker.h"
#import "AsyncSocket.h"

@interface ReceiverConnectionChecker (Private)

- (void) startProbe:(NSTimer *)timer;
- (void) callDelegateWithStatus:(ReceiverConnectionCheckerStatus)status;

@end


@implementation ReceiverConnectionChecker

- (id) initForAddress:(NSString *)address delay:(BOOL)delay withDelegate:(id)delegate {
    if ((self = [super init])) {
        _delegate = delegate;
        _status = ReceiverConnectionChecking;

        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSTimeInterval ti = [defaults floatForKey:@"ReceiverConnectionCheckerDelay"];
        _socketTimeout = [defaults floatForKey:@"ReceiverConnectionCheckerTimeout"];

        _timer = [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(startProbe:) userInfo:address repeats:NO];
        if (!delay)
            [_timer fire];
    }
    return self;
}


- (void) cancelProbe {
    [_timer invalidate];
    _timer = nil;
}

#pragma mark -
#pragma mark AsyncSocket delegate call-backs

-(void)onSocketDidDisconnect:(AsyncSocket *)sock {
    DLog(@"socket did disconnect");
}

-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    DLog(@"%@", err);
    _error = err;
    [self callDelegateWithStatus:ReceiverConnectionError];
}


-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    DLog(@"%@", sock);
}

-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
    NSString * reply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    DLog(@"socket received data: %@", reply);
    
    if ([reply hasPrefix:@"PW"])
        [self callDelegateWithStatus:ReceiverConnectionSuccess];
    else
        [_socket readDataToData:[AsyncSocket CRData] withTimeout:_socketTimeout tag:0];
}

-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    DLog(@"socket did write data, reading data first time");
    [_socket readDataToData:[AsyncSocket CRData] withTimeout:_socketTimeout tag:0];
}


#pragma mark -
#pragma mark Properties

@synthesize status = _status;
@synthesize error = _error;

@end

@implementation ReceiverConnectionChecker (Private)

- (void) startProbe:(NSTimer *)timer {
    _timer = nil;

    NSData * command = [NSData dataWithBytes:"PW?\x0D" length:4];

    _socket = [[AsyncSocket alloc] initWithDelegate:self];
    NSError * err;

    if (![_socket connectToHost:[timer userInfo] onPort:23 withTimeout:_socketTimeout error:&err]) {
        DLog(@"ERROR: %@", err);
        _error = err;
        [self callDelegateWithStatus:ReceiverConnectionError];
    } else {
        [_socket writeData:command withTimeout:_socketTimeout tag:0];
    }
}


- (void) callDelegateWithStatus:(ReceiverConnectionCheckerStatus)status {
    _status = status;
    [_socket disconnect];
    if (_delegate && [_delegate respondsToSelector:@selector(receiverConnectionCheckerDidFinish:)])
        [_delegate performSelectorOnMainThread:@selector(receiverConnectionCheckerDidFinish:) withObject:self waitUntilDone:NO];
}

@end