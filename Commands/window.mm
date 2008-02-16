#import <vector>
#import <string>
#import <sys/stat.h>
#import "../Dialog2.h"
#import "../TMDCommand.h"
#import "../OptionParser.h"
#import "Utilities/TMDChameleon.h"
#import "Utilities/TMDNibController.h"

// ==========
// = Window =
// ==========

@interface TMDWindowCommand : TMDCommand
{
}
@end

// ===================
// = Command handler =
// ===================

std::string find_nib (std::string nibName, std::string currentDirectory, NSDictionary* env)
{
	std::vector<std::string> candidates;

	if(nibName.find(".nib") == std::string::npos)
		nibName += ".nib";

	if(nibName.size() && nibName[0] != '/') // relative path
	{
		candidates.push_back(currentDirectory + "/" + nibName);

		if(char const* bundleSupport = [[env objectForKey:@"TM_BUNDLE_SUPPORT"] UTF8String])
			candidates.push_back(bundleSupport + std::string("/nibs/") + nibName);

		if(char const* supportPath = [[env objectForKey:@"TM_SUPPORT_PATH"] UTF8String])
			candidates.push_back(supportPath + std::string("/nibs/") + nibName);
	}
	else
	{
		candidates.push_back(nibName);
	}

	iterate(it, candidates)
	{
		fprintf(stderr, "candidate: %s\n", it->c_str());
		struct stat sb;
		if(stat(it->c_str(), &sb) == 0)
			return *it;
	}

	fprintf(stderr, "nib could not be loaded: %s (does not exist)\n", nibName.c_str());
	return "";
}

@implementation TMDWindowCommand
+ (void)load
{
	[super registerObject:[self new] forCommand:@"window"];
}

/*
"$DIALOG" -cmp '{title = "title"; prompt = "prompt"; string = "foo"; }' "RequestString"
"$DIALOG" window show -cmp '{title = "title"; prompt = "prompt"; string = "foo"; }' "RequestString"

"$DIALOG" window show -mp '' -d '{ latexEngineOptions = "bar"; }' '/Library/Application Support/TextMate/Bundles/Latex.tmbundle/Support/nibs/tex_prefs.nib'

"$DIALOG" -mp '' -d '{latexEngineOptions = "bar"; }' '/Library/Application Support/TextMate/Bundles/Latex.tmbundle/Support/nibs/tex_prefs.nib'


"$DIALOG" window create -cp '{title = "title"; prompt = "prompt"; }' "RequestString"
"$DIALOG" window close 5
echo '{title = "updated title"; prompt = "updated prompt"; }' | "$DIALOG" window update 1
"$DIALOG" window update -p '{title = "updated title"; prompt = "updated prompt"; }' 2
"$DIALOG" window list

"$DIALOG" window show "/Library/Application Support/TextMate/Bundles/SQL.tmbundle/Support/nibs/connections.nib" -q -d"{'SQL Connections' = ( { title = untitled; serverType = MySQL; hostName = localhost; userName = '$LOGNAME'; } ); }" -n"{ SQL_New_Connection = { title = untitled; serverType = MySQL; hostName = localhost; userName = '$LOGNAME'; }; }" -p'{}' &

"$DIALOG" help window
*/

static option_t const expectedOptions[] =
{
	{ "c", "center",		option_t::no_argument,	option_t::none,				"Centers the new window to the parent window/screen."},
	{ "d", "defaults",	option_t::required_argument, option_t::plist,		"Register initial values for user defaults."},
	{ "m", "modal",		option_t::no_argument,	option_t::none,				"Show window as modal (other windows will be inaccessible)."},
	{ "n", "new-items",	option_t::required_argument, option_t::plist,		"A key/value list of classes (the key) which should dynamically be created at run-time for use as the NSArrayController’s object class. The value (a dictionary) is how instances of this class should be initialized (the actual instance will be an NSMutableDictionary with these values)."},
	{ "p", "parameters",	option_t::required_argument, option_t::plist,		"Provide parameters as a plist."},
	{ "q", "quiet",		option_t::no_argument,option_t::none,					"Do not write result to stdout."},
};

- (void)handleCommand:(id)options
{
	NSArray* args = [options objectForKey:@"arguments"];
	if([args count] < 3)
		ErrorAndReturn(@"no command given (see `\"$DIALOG\" help window` for usage)");

	NSDictionary* res = ParseOptions(args, expectedOptions);

	NSString* command = [args objectAtIndex:2];
	if([command isEqualToString:@"create"] || [command isEqualToString:@"show"])
	{
		if([args count] < 4)
			ErrorAndReturn(@"you must give at least one argument, the name of the nib to show");

		char const* nibName = [[args lastObject] UTF8String];
		char const* nibPath = [[options objectForKey:@"cwd"] UTF8String];
		NSString* nib = [NSString stringWithUTF8String:find_nib(nibName ?: "", nibPath ?: "", [options objectForKey:@"environment"]).c_str()];
		if(nib == nil || [nib length] == 0)
			ErrorAndReturn(@"nib not found. The nib name must be the last argument given");

		id dynamicClasses = [[res objectForKey:@"options"] objectForKey:@"new-items"];
		enumerate([dynamicClasses allKeys], id key)
			[TMDChameleon createSubclassNamed:key withValues:[dynamicClasses objectForKey:key]];

		TMDNibController* nibController = [[[TMDNibController alloc] initWithNibName:nib] autorelease];
		NSDictionary *windowOptions = [res objectForKey:@"options"];
		id parameters = [windowOptions objectForKey:@"parameters"];
		if(! parameters)
			parameters = [TMDCommand readPropertyList:[options objectForKey:@"stdin"]];
		[nibController updateParametersWith:parameters];

		NSDictionary *initialValues = [windowOptions objectForKey:@"defaults"];
		if(initialValues && [initialValues count])
			[[NSUserDefaults standardUserDefaults] registerDefaults:initialValues];

		NSFileHandle* fh = [options objectForKey:@"stdout"];
		if([command isEqualToString:@"show"])
		{
			[nibController notifyFileHandle:fh];
			[nibController setAutoCloses:YES];
		}
		else
		{
			[fh writeString:[nibController token]];
		}
		
		[nibController showWindowAndCenter:[[windowOptions objectForKey:@"center"] boolValue]];
		
		if([[windowOptions objectForKey:@"modal"] boolValue])
			[nibController runModal];
	}
	else if([command isEqualToString:@"wait"])
	{
		NSString* token = [args lastObject];
		if([args count] < 4)
			ErrorAndReturn(@"no window token given");
		TMDNibController* nibController = [TMDNibController controllerForToken:token];
		if(nibController)
			[nibController notifyFileHandle:[options objectForKey:@"stdout"]];
		else
			[[options objectForKey:@"stderr"] writeString:@"There is no window with that token"];
	}
	else if([command isEqualToString:@"update"])
	{
		NSString* token = [args lastObject];
		if([args count] < 4)
			ErrorAndReturn(@"no window token given");
		TMDNibController* nibController = [TMDNibController controllerForToken:token];
		if(nibController)
		{
			id newParameters = [[res objectForKey:@"options"] objectForKey:@"parameters"];
			if(! newParameters)
				newParameters = [TMDCommand readPropertyList:[options objectForKey:@"stdin"]];
			[nibController updateParametersWith:newParameters];
		}
		else
			[[options objectForKey:@"stderr"] writeString:@"There is no window with that token"];
	}
	else if([command isEqualToString:@"list"])
	{
		NSFileHandle* fh = [options objectForKey:@"stdout"];
		NSDictionary *controllers = [TMDNibController controllers];

		if([controllers count] > 0)
		{
			enumerate([controllers allKeys], NSString* token)
			{
				TMDNibController* nibController = [controllers objectForKey:token];
				[fh writeString:[NSString stringWithFormat:@"%@ (%@)\n", token, [[nibController window] title]]];
			}
		}
		else
			[fh writeString:@"There are no active windows\n"];
	}
	else if([command isEqualToString:@"close"])
	{
		NSString* token = [args lastObject];
		if([args count] < 4)
			ErrorAndReturn(@"no window token given");
		if([TMDNibController controllerForToken:token])
			[[TMDNibController controllerForToken:token] tearDown];
		else
			[[options objectForKey:@"stderr"] writeString:@"There is no window with that token"];
	}
}

- (NSString *)commandDescription
{
	return @"Displays custom dialogs from NIBs.";
}

- (NSString *)usageForInvocation:(NSString *)invocation;
{
	return [NSString stringWithFormat:
		@"%@ show/create «options» «nib path»\n"
		@"%@ update/ [-p «parameters»] «window token»\n"
		@"%@ update wait/close «window token»\n"
		@"\nParameters should be provided as a propertly list.\n"
		@"\nOptions:\n%@",
		invocation, invocation, invocation, GetOptionList(expectedOptions)];
}
@end
