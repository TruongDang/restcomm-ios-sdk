//
//  MessageTableViewController.h
//  restcomm-messenger
//
//  Created by Antonis Tsakiridis on 9/23/15.
//  Copyright © 2015 TeleStax. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RestCommClient.h"

@interface MessageTableViewController : UITableViewController
- (void)appendToDialog:(NSString*)msg sender:(NSString*)sender;

@property (weak) RCDevice * device;
@property NSMutableDictionary * parameters;
@end