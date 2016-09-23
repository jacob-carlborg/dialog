#import "../Dialog2.h"
#import "../TMDCommand.h"

/*
 echo '{popoverStyle = warning; button1 = 'OK'; title = 'test'; body = 'Testing';}' | "$DIALOG" popover

 "$DIALOG" help popover
 "$DIALOG" popover --popoverStyle critical --title "FOOL!" --body "test" --button1 foo --button2 bar --button3 baz
 */

// =========
// = Popover =
// =========

@interface TMDPopoverCommand : TMDCommand
@end

//NSPopoverStyle popover_style_from_string (NSString* str)
//{
//	if([str isEqualToString:@"warning"])
//		return NSWarningPopoverStyle;
//	else if([str isEqualToString:@"critical"])
//		return NSCriticalPopoverStyle;
//	else
//		return NSInformationalPopoverStyle;
//}

@implementation TMDPopoverCommand
+ (void)load
{
	[super registerObject:[self new] forCommand:@"popover"];
}

- (void)handleCommand:(CLIProxy*)proxy
{
	 //	NSDictionary* args = [proxy parameters];
	 //
	 //	NSPopover* popover = [NSPopover new];
	 //	[popover setPopoverStyle:popover_style_from_string([args objectForKey:@"popoverStyle"])];
	 //	if(NSString* msg = [args objectForKey:@"title"])
	 //		[popover setMessageText:msg];
	 //	if(NSString* txt = [args objectForKey:@"body"])
	 //		[popover setInformativeText:txt];
	 //
	 //	NSInteger i = 0;
	 //	while(NSString* button = [args objectForKey:[NSString stringWithFormat:@"button%ld", ++i]])
	 //		[popover addButtonWithTitle:button];
	 //
	 //	NSInteger popoverResult = ([popover runModal] - NSPopoverFirstButtonReturn);
	 //	NSDictionary* resultDict = @{ @"buttonClicked" : @(popoverResult) };
	 //
	 //	[TMDCommand writePropertyList:resultDict toFileHandle:[proxy outputHandle]];
	 }

	 - (NSString*)commandDescription
	{
		return @"Show a popover.";
	}

	 - (NSString*)usageForInvocation:(NSString*)invocation;
	{
		return [NSString stringWithFormat:@"\t%1$@ --popoverStyle warning --title 'Delete File?' --body 'You cannot undo this action.' --button1 Delete --button2 Cancel\n", invocation];
	}
	 @end
