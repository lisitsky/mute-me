#import "AppDelegate.h"
#import "TouchBar.h"
#import <ServiceManagement/ServiceManagement.h>
#import "TouchButton.h"
#import "TouchDelegate.h"
#import <Cocoa/Cocoa.h>
#import <MASShortcut/Shortcut.h>

static const NSTouchBarItemIdentifier muteIdentifier = @"pp.mute";

@interface AppDelegate () <TouchDelegate>

@end

@implementation AppDelegate

NSButton *touchBarButton;

@synthesize statusBar;

- (void) awakeFromNib {
    
    
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    NSImage* statusImage = [NSImage imageNamed:@"statusBarIcon"];
    
    statusImage.size = NSMakeSize(18, 18);
    
    // allows cocoa to change the background of the icon
    [statusImage setTemplate:YES];
    
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusBar.image = statusImage;
    self.statusBar.highlightMode = YES;
    self.statusBar.enabled = YES;
    self.statusBar.menu = self.statusMenu;
    
    // masshortcut
    
    // default shortcut is "Shift Command o"
    MASShortcut *firstLaunchShortcut = [MASShortcut shortcutWithKeyCode:kVK_ANSI_O modifierFlags:NSEventModifierFlagCommand | NSEventModifierFlagShift];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [[MASShortcutMonitor sharedMonitor] registerShortcut:firstLaunchShortcut withAction:^{
            [self shortCutKeyPressed];
        }];
    
    
    // Register default values to be used for the first app start
    /*
    [defaults registerDefaults:@{
        MASHardcodedShortcutEnabledKey : @YES,
        MASCustomShortcutEnabledKey : @YES,
		MASCustomShortcutKey : firstLaunchShortcutData
    }];*/

    // Bind the shortcut recorder view’s value to user defaults.
    // Run “defaults read com.shpakovski.mac.Demo” to see what’s stored
    // in user defaults.
    //[_customShortcutView setAssociatedUserDefaultsKey:MASCustomShortcutKey];

    // Enable or disable the recorder view according to the first checkbox state
    //[_customShortcutView bind:@"enabled" toObject:defaults
     //   withKeyPath:MASCustomShortcutEnabledKey options:nil];
    
    
}

- (void) shortCutKeyPressed {

    NSLog (@"shortcut key pressed");

    [self menuMenuItemAction:nil];

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[[[NSApplication sharedApplication] windows] lastObject] close];

    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);

    NSCustomTouchBarItem *mute =
    [[NSCustomTouchBarItem alloc] initWithIdentifier:muteIdentifier];

    NSImage *muteImage = [NSImage imageNamed:NSImageNameTouchBarAudioInputMuteTemplate];
    TouchButton *button = [TouchButton buttonWithImage: muteImage target:nil action:nil];
    [button setBezelColor: [self colorState: [self currentStateFixed]]];
    [button setDelegate: self];
    mute.view = button;

    touchBarButton = button;

    [NSTouchBarItem addSystemTrayItem:mute];
    DFRElementSetControlStripPresenceForIdentifier(muteIdentifier, YES);

    // set the menuBar Item
    double currentState = [self currentStateFixed];

    NSLog(@"currentState : %f", currentState);

    if (currentState == 0) {
        [self.muteMenuItem setState:NSOnState];
        
        [self setStatusBarImgRed:YES];
    }


    [self enableLoginAutostart];

}

- (void) setStatusBarImgRed:(BOOL) shouldBeRed {

    NSImage* statusImage = [NSImage imageNamed:@"statusBarIcon"];
    statusImage.size = NSMakeSize(18, 18);
    [statusImage setTemplate:!shouldBeRed];
        
    self.statusBar.image = statusImage;
}


-(void) enableLoginAutostart {

    // on the first run this should be nil. So don't setup auto run
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"auto_login"] == nil) {
        return;
    }

    BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:@"auto_login"];
    if(!SMLoginItemSetEnabled((__bridge CFStringRef)@"Pixel-Point.Mute-Me-Now-Launcher", !state)) {
        NSLog(@"The login was not succesfull");
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

-(double) currentState {
    NSAppleEventDescriptor *result = [self excecuteAppleScript:@"volume_sript"];
    NSData *data = [result data];
    double currentPosition = 0;
    [data getBytes:&currentPosition length:[data length]];
    return currentPosition;
}

// return the correct microphone volume
-(double) currentStateFixed {
    NSAppleEventDescriptor *result = [self excecuteAppleScript:@"volume_sript"];
    return [result doubleValue];
}


-(double) changeState {
    NSAppleEventDescriptor *result = [self excecuteAppleScript:@"mute_sript"];
    NSData *data = [result data];
    double currentPosition = 0;
    [data getBytes:&currentPosition length:[data length]];
    return currentPosition;
}

-(NSAppleEventDescriptor *) excecuteAppleScript:(NSString *)withName {
    NSString* path = [[NSBundle mainBundle] pathForResource:withName ofType:@"scpt"];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    NSDictionary* errors = [NSDictionary dictionary];
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
    
    return [appleScript executeAndReturnError:nil];
}

-(NSColor *)colorState:(double)volume {

    if(volume == 0.0) {
        return NSColor.redColor;
    } else {
        return NSColor.clearColor;
    }
}

- (void)onPressed:(TouchButton*)sender
{
    double volume = [self changeState];
    
    NSButton *button = (NSButton *)sender;
    [button setBezelColor: [self colorState: volume]];
    
}

- (void)onLongPressed:(TouchButton*)sender
{
    [[[[NSApplication sharedApplication] windows] lastObject] makeKeyAndOrderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:true];
}

- (IBAction)prefsMenuItemAction:(id)sender {

    [self onLongPressed:sender];
}

- (IBAction)quitMenuItemAction:(id)sender {
    [NSApp terminate:nil];
}

- (IBAction)menuMenuItemAction:(id)sender {

    if (self.muteMenuItem.state == NSOffState) {

        self.muteMenuItem.state = NSOnState;
        [self setStatusBarImgRed:YES];
        
    } else {
        self.muteMenuItem.state = NSOffState;
        [self setStatusBarImgRed:NO];
    }
    
    [self changeState];
}



@end
