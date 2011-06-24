//
//  SettingsViewController.m
//  Briefcase
//
//  Created by Michael Taylor on 10-01-30.
//  Copyright 2010 Hey Mac Software. All rights reserved.
//

#import "HMCore.h"
#import "SettingsViewController.h"
#import "ConnectionController.h"
#import "KeychainKeyPair.h"
#import "SSHConnection.h"

static SettingsViewController * theSettingsController = nil;

@interface SettingsViewController (Private)

- (void)reportProblem;

@end

@implementation SettingsViewController

+(SettingsViewController*)sharedController
{
    if (!theSettingsController)
        theSettingsController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    return theSettingsController;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark SSH Keys

- (void)_regenerationDone
{
    // We need to update the table
    [self.tableView beginUpdates];
    
    NSIndexPath * regen_path, * email_path, * copy_path;
    regen_path = [NSIndexPath indexPathForRow:0 inSection:0];
    email_path = [NSIndexPath indexPathForRow:1 inSection:0];
    copy_path  = [NSIndexPath indexPathForRow:2 inSection:0];
    NSArray * index_paths = [NSArray arrayWithObjects:regen_path, email_path,
                             copy_path, nil];
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:regen_path]
                          withRowAnimation:YES];
    [self.tableView insertRowsAtIndexPaths:index_paths
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates]; 
    
    NSNotificationCenter * center;
    center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)regenerateSSHKeys
{    
    BOOL had_key = [SSHConnection hasSSHKeyPair];
    
    [SSHConnection regenerateSSHKeyPair];
    
    if (!had_key)
    {
        NSNotificationCenter * center;
        center = [NSNotificationCenter defaultCenter];
        
        [center addObserver:self
                   selector:@selector(_regenerationDone) 
                       name:kSSHKeyPairGenerationCompleted
                     object:nil];
    }
}

- (void)emailSSHKey
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController * mail_controller = [[MFMailComposeViewController alloc] init];
        mail_controller.mailComposeDelegate = self;
	
        KeychainKeyPair * pair = [SSHConnection sshKeyPair];
        NSString * key_string = [[NSString alloc] initWithData:pair.publicKey
                                                      encoding:NSASCIIStringEncoding];	
        [mail_controller setSubject:@"Public Key"];
        [mail_controller setMessageBody:key_string isHTML:NO];
        
        [key_string release];
	
        [self presentModalViewController:mail_controller animated:YES];
    }
    else 
    {
        UIAlertView * email_alert;
        NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Your %@ is not configured to send email",@"Message when trying to send email attachment from device with no email accounts set up"),
                              [UIDevice currentDevice].model];
        email_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email Error",@"Title when cannot send email") 
                                                 message:message
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
                                       otherButtonTitles:nil];
        [email_alert show];
    }
}

- (void)copySSHKeyToClipboard
{
    KeychainKeyPair * pair = [SSHConnection sshKeyPair];
    NSString * key_string = [[NSString alloc] initWithData:pair.publicKey
                                                  encoding:NSASCIIStringEncoding];	

    UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = key_string;
    
    [key_string release];
    
    UIAlertView *alert = 
    alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Public Key",@"Title for public key copy alert")
                                       message:NSLocalizedString(@"Your public key has been copied to the clipboard",@"Message for public key copy alert")
                                      delegate:nil 
                             cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
                             otherButtonTitles:nil];
    [alert show];	
    [alert release];
    
}

#pragma mark Problem Reports

- (void)reportProblem
{
    if ([MFMailComposeViewController canSendMail])
    {
	MFMailComposeViewController * mail_controller = [[MFMailComposeViewController alloc] init];
	mail_controller.mailComposeDelegate = self;
	
	NSData * attachment_data = [[HMLogManager sharedLogManager] logData];
	[mail_controller addAttachmentData:attachment_data
				  mimeType:@"text/plain" 
				  fileName:@"Briefcase.log"];
	
	[mail_controller setSubject:@"Briefcase Problem"];
	[mail_controller setToRecipients:[NSArray arrayWithObject:@"support@heymacsoftware.com"]];
	
        //	UIDevice * device = [UIDevice currentDevice];
        //	NSString * format = NSLocalizedString(@"Sent from Briefcase on my %@", @"Default message body for emails sent from Briefcase. The name of the device (eg iPhone) is substituted in");
        //	NSString * message = [NSString stringWithFormat:format, device.model];
	[mail_controller setMessageBody:[NSString string] isHTML:NO];
	
	[self presentModalViewController:mail_controller animated:YES];
    }
    else 
    {
        UIAlertView * email_alert;
        NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Your %@ is not configured to send email",@"Message when trying to send email attachment from device with no email accounts set up"),
                              [UIDevice currentDevice].model];
        email_alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email Error",@"Title when cannot send email") 
                                                 message:message
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
                                       otherButtonTitles:nil];
        [email_alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller 
	  didFinishWithResult:(MFMailComposeResult)result 
			error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
        {
            // SSL Keys
            return [SSHConnection hasSSHKeyPair] ? 3 : 1;
        }
        case 1:
            // Feedback
            return 1;
        default:
            break;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Public Key Authentication", @"Title for SSL key settings section");
            break;
        case 1:
            return NSLocalizedString(@"Feedback", @"Title for feedback settings section");
            break;
        default:
            break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * cell_identifier = @"settings";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:cell_identifier] autorelease];
    }
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    switch (indexPath.section) 
    {
        case 0:
        {
            // SSH Keys
            switch (indexPath.row) 
            {
                case 0:
                    if ([SSHConnection hasSSHKeyPair])
                        cell.textLabel.text = NSLocalizedString(@"Regenerate Key Pair",@"Menu button for generating a new SSL key pair");
                    else
                        cell.textLabel.text = NSLocalizedString(@"Generate Key Pair",@"Menu button for generating a new SSL key pair");
                    break;
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"Email Public Key",@"Menu button for emailing a public key");
                    break;
                case 2:
                    cell.textLabel.text = NSLocalizedString(@"Copy Public Key",@"Menu button for copy a public key to the clipboard");
                    break;
                default:
                    break;
            }
            break;
        }
        case 1:
            // Feedback
            switch (indexPath.row) 
	{
	    case 0:
		cell.textLabel.text = NSLocalizedString(@"Report Problem",@"Menu button for reporting a problem");
		break;
	    default:
		break;
	}
            break;
        default:
            break;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    switch (indexPath.section) 
    {
        case 0:
            // Feedback
            switch (indexPath.row) 
        {
            case 0:
                [self regenerateSSHKeys];
                break;
            case 1:
                [self emailSSHKey];
                break;
            case 2:
                [self copySSHKeyToClipboard];
                break;
            default:
                break;
        }
            break;
        case 1:
            // Feedback
            switch (indexPath.row) 
        {
            case 0:
                [self reportProblem];
                break;
            default:
                break;
        }
            break;
        default:
            break;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath 
                                  animated:NO];
}

- (void)dealloc {
    [super dealloc];
}

@end

