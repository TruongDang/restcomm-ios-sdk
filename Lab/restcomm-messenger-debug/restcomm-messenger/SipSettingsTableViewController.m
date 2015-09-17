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
#import "SipSettingsTableViewController.h"
#import "MainNavigationController.h"
#import "Utils.h"

//char AOR[] = "sip:antonis-2@telestax.com";
// elastic
//char REGISTRAR[] = "23.23.228.238:5080";
//char REGISTRAR[] = "192.168.2.32:5080";


@interface SipSettingsTableViewController ()
@property (weak, nonatomic) IBOutlet UITextField *aorText;
@property (weak, nonatomic) IBOutlet UITextField *registrarText;
//@property (weak, nonatomic) IBOutlet UISwitch *muteSwitch;
@property (weak, nonatomic) IBOutlet UITextField *passwordText;
@end

@implementation SipSettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // turn auto-correct in text fields; doesn't help with SIP uris
    self.aorText.autocorrectionType = UITextAutocorrectionTypeNo;
    self.registrarText.autocorrectionType = UITextAutocorrectionTypeNo;
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];
    
    [self.view addGestureRecognizer:tapGesture];
    
    // set some defaults when in debug to avoid typing
    //self.aorText.text = [NSString stringWithUTF8String:AOR];
    //self.registrarText.text = [NSString stringWithUTF8String:REGISTRAR];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.aorText.text = [[self.device getParams] objectForKey:@"aor"];
    NSString * fullRegistrar = [[self.device getParams] objectForKey:@"registrar"];
    NSRange range = [fullRegistrar rangeOfString:@":"];
    self.registrarText.text = [fullRegistrar substringFromIndex:range.location + 1];
    self.passwordText.text = [[self.device getParams] objectForKey:@"password"];
    // Latest:
    //UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style: UIBarButtonItemStyleBordered target:self action:@selector(backPressed)];
    //self.navigationItem.leftBarButtonItem = backButton;
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        [self update];
    }
    [super viewWillDisappear:animated];
}

- (IBAction)backPressed
{
    //[self dismissViewControllerAnimated:YES completion:nil]; // ios 6
    [self update];
}

- (void)hideKeyBoard
{
    // resign both to be sure
    [self.aorText resignFirstResponder];
    [self.registrarText resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)update
{
    /**/
    //TabBarController * tabBarController = (TabBarController*)self.tabBarController;
    //this.device = tabBarController.viewController.device;
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    bool update = false;
    if (![self.aorText.text isEqualToString:@""]) {
        [params setObject:self.aorText.text forKey:@"aor"];
        update = true;
    }
    if (![self.registrarText.text isEqualToString:@""]) {
        [params setObject:[NSString stringWithFormat:@"sip:%@", self.registrarText.text] forKey:@"registrar"];
        update = true;
    }
    if (![self.passwordText.text isEqualToString:@""]) {
        [params setObject:self.passwordText.text forKey:@"password"];
        update = true;
    }
    
    if (update) {
        //SettingsNavigationController *settingsNavigationController = (SettingsNavigationController*)self.navigationController;
        [self.device updateParams:params];
    }
    /**/
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