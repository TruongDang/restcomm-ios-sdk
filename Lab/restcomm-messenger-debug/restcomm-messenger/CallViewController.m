/*
 * TeleStax, Open Source Cloud Communications
 * Copyright 2011-2015, Telestax Inc and individual contributors
 * by the @authors tag.
 *
 * This program is free software: you can redistribute it and/or modify
 * under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 * For questions related to commercial use licensing, please contact sales@telestax.com.
 *
 */

#import "CallViewController.h"
#import "RestCommClient.h"
#import "Utilities.h"

@interface CallViewController ()
@property (weak, nonatomic) IBOutlet UIButton *hangupButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *audioButton;
@property (weak, nonatomic) IBOutlet UIButton *muteVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteAudioButton;
//@property (weak, nonatomic) IBOutlet UISwitch *muteSwitch;
// who we are calling/get called from
@property (weak, nonatomic) IBOutlet UILabel *callLabel;
// signaling/media status to inform the user how call setup goes (like Android toasts)
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property ARDVideoCallView *videoCallView;
@property RTCVideoTrack *remoteVideoTrack;
@property RTCVideoTrack *localVideoTrack;
@property BOOL isAudioMuted, isVideoMuted;
@property BOOL pendingError;
@end

@implementation CallViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pendingError = NO;
    //self.muteSwitch.enabled = false;
    self.isVideoMuted = NO;
    self.isAudioMuted = NO;
    
    self.videoCallView = [[ARDVideoCallView alloc] initWithFrame:self.view.frame];
    self.videoCallView.hidden = YES;
    //self.videoCallView.delegate = self;
    [self.view insertSubview:self.videoCallView belowSubview:self.hangupButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.muteAudioButton.hidden = YES;
    self.muteVideoButton.hidden = YES;
    if ([[self.parameters valueForKey:@"invoke-view-type"] isEqualToString:@"make-call"]) {
        self.videoButton.hidden = YES;
        self.audioButton.hidden = YES;
    }
    if ([[self.parameters valueForKey:@"invoke-view-type"] isEqualToString:@"receive-call"]) {
        self.videoButton.hidden = NO;
        self.audioButton.hidden = NO;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([[self.parameters valueForKey:@"invoke-view-type"] isEqualToString:@"make-call"]) {
        // call the other party
        if (self.connection) {
            NSLog(@"Connection already ongoing");
            return;
        }
        NSString *username = [Utilities usernameFromUri:[self.parameters objectForKey:@"username"]];
        self.callLabel.text = [NSString stringWithFormat:@"Calling %@", username];
        self.statusLabel.text = @"Initiating Call...";
        
        self.connection = [self.device connect:self.parameters delegate:self];
        if (self.connection == nil) {
            [self.presentingViewController dismissViewControllerAnimated:YES
                                                              completion:nil];
        }
    }
    if ([[self.parameters valueForKey:@"invoke-view-type"] isEqualToString:@"receive-call"]) {
        NSString *username = [Utilities usernameFromUri:[self.parameters objectForKey:@"username"]];
        self.callLabel.text = [NSString stringWithFormat:@"Call from %@", username];
        self.statusLabel.text = @"Call received";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)answerPressed:(id)sender
{
    [self answer:NO];
}

- (IBAction)answerVideoPressed:(id)sender
{
    [self answer:YES];
}

- (void)answer:(BOOL)allowVideo
{
    if (self.pendingIncomingConnection) {
        self.statusLabel.text = @"Answering Call...";
        if (allowVideo) {
            [self.pendingIncomingConnection accept:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                               forKey:@"video-enabled"]];
        }
        else {
            [self.pendingIncomingConnection accept:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                                               forKey:@"video-enabled"]];
        }
        self.connection = self.pendingIncomingConnection;
        self.pendingIncomingConnection = nil;
    }
}

/*
- (IBAction)declinePressed:(id)sender
{
    if (self.pendingIncomingConnection) {
        // reject the pending RCConnection
        [self.pendingIncomingConnection reject];
        self.pendingIncomingConnection = nil;
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    }
}
 */

- (IBAction)hangUpPressed:(id)sender
{
    if (self.pendingIncomingConnection) {
        // incomind ringing
        self.statusLabel.text = @"Rejecting Call...";
        [self.pendingIncomingConnection reject];
        self.pendingIncomingConnection = nil;
    }
    else {
        if (self.connection) {
            self.statusLabel.text = @"Disconnecting Call...";
            [self.connection disconnect];
            self.connection = nil;
            self.pendingIncomingConnection = nil;
            [self stopVideoRendering];
        }
        else {
            NSLog(@"Error: not connected/connecting/pending");
        }
    }
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

/*
- (IBAction)cancelPressed:(id)sender
{
    if (self.connection) {
        [self.connection disconnect];
    }
}

- (void)disconnect
{
    if (self.connection) {
        [self.connection disconnect];
    }
    [self stopVideoRendering];
}
 */

- (void)stopVideoRendering
{
    if (self.remoteVideoTrack) {
        [self.remoteVideoTrack removeRenderer:self.videoCallView.remoteVideoView];
        self.remoteVideoTrack = nil;
        [self.videoCallView.remoteVideoView renderFrame:nil];
    }
    if (self.localVideoTrack) {
        [self.localVideoTrack removeRenderer:self.videoCallView.localVideoView];
        self.localVideoTrack = nil;
        [self.videoCallView.localVideoView renderFrame:nil];
    }
}

// ---------- Video View delegate methods:
/*
- (void)videoCallViewDidHangup:(ARDVideoCallView *)view
{
    [self disconnect];
}
 */

// ---------- Delegate methods for RC Connection
- (void)connection:(RCConnection*)connection didFailWithError:(NSError*)error
{
    NSLog(@"connection didFailWithError");
    self.pendingError = YES;
    self.connection = nil;
    self.pendingIncomingConnection = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"RCConnection Error"
                                                    message:[[error userInfo] objectForKey:NSLocalizedDescriptionKey]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

// optional
// 'ringing' for outgoing connections
- (void)connectionDidStartConnecting:(RCConnection*)connection
{
    NSLog(@"connectionDidStartConnecting");
    self.statusLabel.text = @"Did start connecting";
}

- (void)connectionDidConnect:(RCConnection*)connection
{
    NSLog(@"connectionDidConnect");
    self.statusLabel.text = @"Connected";
    // hide video/audio buttons
    self.videoButton.hidden = YES;
    self.audioButton.hidden = YES;
    
    // show mute video/audio buttons
    self.muteAudioButton.hidden = NO;
    self.muteVideoButton.hidden = NO;

}

- (void)connectionDidCancel:(RCConnection*)connection
{
    NSLog(@"connectionDidCancel");
    
    if (self.pendingIncomingConnection) {
        self.statusLabel.text = @"Remote party Cancelled";
        self.pendingIncomingConnection = nil;
        self.connection = nil;
        [self stopVideoRendering];

        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    }
}

- (void)connectionDidDisconnect:(RCConnection*)connection
{
    NSLog(@"connectionDidDisconnect");
    self.statusLabel.text = @"Disconnected";
    self.connection = nil;
    self.pendingIncomingConnection = nil;
    [self stopVideoRendering];

    // hide mute video/audio buttons
    self.muteAudioButton.hidden = YES;
    self.muteVideoButton.hidden = YES;

    if (!self.pendingError) {
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    }
    /*
    else {
        self.pendingError = NO;
    }
     */
}

- (void)connectionDidGetDeclined:(RCConnection*)connection
{
    NSLog(@"connectionDidGetDeclined");
    self.statusLabel.text = @"Got Declined";

    self.connection = nil;
    self.pendingIncomingConnection = nil;
    [self stopVideoRendering];

    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

- (void)connection:(RCConnection *)connection didReceiveLocalVideo:(RTCVideoTrack *)localVideoTrack
{
    if (!self.localVideoTrack) {
        self.statusLabel.text = @"Received local video";
        self.localVideoTrack = localVideoTrack;
        [self.localVideoTrack addRenderer:self.videoCallView.localVideoView];
    }
}

- (void)connection:(RCConnection *)connection didReceiveRemoteVideo:(RTCVideoTrack *)remoteVideoTrack
{
    if (!self.remoteVideoTrack) {
        self.statusLabel.text = @"Received remote video";
        self.remoteVideoTrack = remoteVideoTrack;
        [self.remoteVideoTrack addRenderer:self.videoCallView.remoteVideoView];
        self.videoCallView.hidden = NO;
    }
}

- (IBAction)toggleMuteAudio:(id)sender
{
    // if we aren't in connected state it doesn't make any sense to mute
    if (self.connection.state != RCConnectionStateConnected) {
        return;
    }
    
    if (!self.isAudioMuted) {
        self.connection.muted = true;
        self.isAudioMuted = YES;
        [self.muteAudioButton setImage:[UIImage imageNamed:@"audio-muted-23x28.png"] forState:UIControlStateNormal];
    }
    else {
        self.connection.muted = false;
        self.isAudioMuted = NO;
        [self.muteAudioButton setImage:[UIImage imageNamed:@"audio-active-23x28.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)toggleMuteVideo:(id)sender
{
    // if we aren't in connected state it doesn't make any sense to mute
    if (self.connection.state != RCConnectionStateConnected) {
        return;
    }
    
    if (!self.isVideoMuted) {
        self.connection.videoMuted = true;
        self.isVideoMuted = YES;
        [self.muteVideoButton setImage:[UIImage imageNamed:@"video-muted-30x22.png"] forState:UIControlStateNormal];
    }
    else {
        self.connection.videoMuted = false;
        self.isVideoMuted = NO;
        [self.muteVideoButton setImage:[UIImage imageNamed:@"video-active-30x22.png"] forState:UIControlStateNormal];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.pendingError = NO;
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end