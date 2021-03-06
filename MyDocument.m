//
//  MyDocument.m
//  MacMud
//
//  Created by Mike Pattee on 7/2/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "RegexKitLite.h"
//#import <OmniFoundation/OFRegularExpression.h>
//#import <OmniFoundation/OFRegularExpressionMatch.h>


@implementation MyDocument

@synthesize hostAddressTextField;
@synthesize portTextField;
@synthesize inputTextField;

@synthesize outputTextView;
@synthesize experienceLabel;

@synthesize lastInput;

- (id)init
{
    self = [super init];
    if (self) {
		byteIndex = 0;
		totalExperienceGained = 0;
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	[outputTextView insertText:@"Click Connect to start"];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

#pragma mark -
#pragma mark Custom Actions
- (IBAction)connect:(id)sender
{
	NSString *hostAddress = [hostAddressTextField stringValue];
	NSInteger port = [portTextField integerValue];
	if (![hostAddress isEqualToString:@""]) {
//		[searchField setEnabled:NO];
		NSHost *host = [NSHost hostWithName:hostAddress];
		// iStream and oStream are instance variables
		[NSStream getStreamsToHost:host port:port inputStream:&iStream outputStream:&oStream];
		[iStream retain];
		[oStream retain];
		[iStream setDelegate:self];
		[oStream setDelegate:self];
		[iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[iStream open];
		[oStream open];
			
	}
}

#pragma mark -
#pragma mark stream delegates
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
//	NSLog(@"eventCode: %d", eventCode);
//	NSLog(@"iStream status: %d", [iStream streamStatus]);
//	NSLog(@"oStream status: %d", [oStream streamStatus]);
//	
//	NSLog(@"iStream error: %@", [[iStream streamError] localizedDescription]);
//	NSLog(@"oStream error: %@", [[oStream streamError] localizedDescription]);
	
	switch (eventCode) {
		case NSStreamEventHasBytesAvailable:
		{
			if (!_data) {
				_data = [[NSMutableData data] retain];
			}
			uint8_t buf[8192];
			unsigned int len = 0;
			len = [(NSInputStream *)stream read:buf maxLength:8192];
			if(len) {
				[_data appendBytes:(const void*)buf length:len];
//				if (len == 8192) {
//					NSLog(@"MAX BYTES READ");
//				} else {
//					NSLog(@"Bytes Read: %u", len);
//				}
				// bytesRead is an instance variable of type NSNumber.
				[self processIncoming];
//				bytesRead = bytesRead + len;
//				[bytesRead setIntValue:[bytesRead intValue] + len];
			} else {
				NSLog(@"no buffer");
			}
			break;
		}
		case NSStreamEventEndEncountered:
		{
			[stream close];
			[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			[stream release];
			stream = nil; // stream is ivar so reinit it
			break;
		}
		case NSStreamEventHasSpaceAvailable:
		{
//			uint8_t *readBytes = (uint8_t *)[_data mutableBytes];
//			readBytes += byteIndex; // instance variable to move pointer
//			int data_len = [_data length];
//			unsigned int len = ((data_len - byteIndex >= 1024) ? 1024 : (data_len - byteIndex));
//			uint8_t buf[len];
//			(void)memcpy(buf, readBytes, len);
//			len = [(NSOutputStream *)stream write:(const uint8_t *)buf maxLength:len];
//			byteIndex += len;
			break;
		}
			
		default:
			break;
	}
}

- (IBAction)toggleAutoAttack:(id)sender
{
//	NSLog(@"toggle auto attack called");
	if (isAutoAttacking) {
		isAutoAttacking = NO;
		[checkForTargetsTimer invalidate];
	} else {
		isAutoAttacking = YES;
		checkForTargetsTimer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(checkForTargets:) userInfo:nil repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:checkForTargetsTimer forMode:NSDefaultRunLoopMode];
	}
}

- (void)checkForTargets:(NSTimer *)theTimer
{
//	NSLog(@"checkForTargets called isInCombat: %d, theTimer:%@", isInCombat, theTimer);
	if (!isInCombat) {
		[self sendCommand:@""];		
	}
}

- (void)processIncoming
{
	NSString *rawString = [[NSString alloc] initWithData:_data encoding:NSASCIIStringEncoding];
	[_data release];
	_data = nil;

	NSString *cursorPosition = [NSString stringWithFormat:@"%c\\[\\d*;\\d*H", 27];
	NSString *eraseDisplay = [NSString stringWithFormat:@"%c\\[2J", 27];
//	NSString *attributeFormat = [NSString stringWithFormat:@"%c\\[\\d*;\\d*m", 27];
	NSString *ANSIAttribute = [NSString stringWithFormat:@"%c\\[(\\d+);?(\\d*);?(\\d*)m", 27];
	NSString *cursorBackward = [NSString stringWithFormat:@"%c\\[\\d+D", 27];
	NSString *eraseLine = [NSString stringWithFormat:@"%c\\[K", 27];

	NSString *string = [rawString stringByReplacingOccurrencesOfRegex:cursorPosition withString:@""];
	// TODO: handle others than 1,1
	string = [string stringByReplacingOccurrencesOfRegex:eraseDisplay withString:@""];
	// TODO: clear display
	string = [string stringByReplacingOccurrencesOfRegex:cursorBackward withString:@""];
	// TODO: Move other distances backward than 79
	string = [string stringByReplacingOccurrencesOfRegex:eraseLine withString:@""];
	// TODO: Erase line from display

	NSArray *matches = [string componentsMatchedByRegex:ANSIAttribute];
	NSArray *matchComponents = [string arrayOfCaptureComponentsMatchedByRegex:ANSIAttribute];
//	NSLog(@"array: %@", matches);
	if (matches) {
		NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
		string = [string stringByReplacingOccurrencesOfRegex:ANSIAttribute withString:@""];
		
		//		if ([string grep:allAttributesOff options:0] == YES) {
		//			string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%c[0m", 27] withString:@""];
		//		}

//				// 0;35m == attackable magenta
//				// 0;36m == neutral cyan
//				// 0;37m == good alligned white
		
		
		for (NSArray *match in matchComponents) 
			{
			NSRange range = [[attributedString string] rangeOfString:[match objectAtIndex:0]];
			NSRange colorRange = range;
			colorRange.length = [attributedString length] - range.location;
			NSString *parsedCode = [match objectAtIndex:2];
			if ([parsedCode length]) 
				{
				[self attributedString:attributedString withCode:[[match objectAtIndex:2] integerValue] forRange:colorRange];
				}
			[attributedString deleteCharactersInRange:range];
			}
	
		[outputTextView insertText:attributedString];

		self.lastInput = [attributedString string];

		NSDictionary *inputDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:attributedString, rawString, nil] forKeys:[NSArray arrayWithObjects:@"attributedString", @"rawString", nil]];
		[self performSelectorInBackground:@selector(respondInBackgroundToInput:) withObject:inputDictionary];
		[attributedString release];
		
	} else {
		self.lastInput = string;
		[outputTextView insertText:string];
	}
	[rawString release];
	
}

- (void)respondInBackgroundToInput:(NSDictionary *)anInputDictionary
{
	BOOL shouldCheckForTargets = NO;
	NSAutoreleasePool *backgroundPool = [[NSAutoreleasePool alloc] init];

	NSAttributedString *attributedString = [anInputDictionary valueForKey:@"attributedString"];
	NSString *rawString = [anInputDictionary valueForKey:@"rawString"];

	NSString *string = [attributedString string];

//	OFRegularExpression *regExObj = nil;
//	OFRegularExpressionMatch *match = nil;
	if (!isInCombat) {
		NSArray *targetMatches = [[attributedString string] componentsMatchedByRegex:@"Also here: (.+)\\." capture:1];
		if ([targetMatches count]) 
			{
			NSArray *targets = [[targetMatches objectAtIndex:0] componentsSeparatedByString:@", "];
			for (NSString *target in targets) 
				{
				NSLog(@"TARGET: %@", target);
				NSString *ANSIAttribute = [NSString stringWithFormat:@"%c\\[(\\d+);?(\\d*);?(\\d*)m", 27];				
				NSString *cleanedTarget = [target stringByReplacingOccurrencesOfRegex:ANSIAttribute withString:@""];
				if (islower([target characterAtIndex:0])) 
					{
					NSLog(@"BLAHLFKJSDFLKJ");
					[self performSelectorOnMainThread:@selector(attackTarget:) withObject:cleanedTarget waitUntilDone:NO];
//					[self attackTarget:[target stringByReplacingOccurrencesOfRegex:ANSIAttribute withString:@""]];
					break;
					}
				}
			}
		}

	NSString *combat = [NSString stringWithFormat:@"Combat Off|Combat Engaged"];
	NSString *combatMatch = [string stringByMatching:combat];
	if ([combatMatch isEqualToString:@"Combat Engaged"]) 
		{
		isInCombat = YES;
		NSLog(@"Combat Engaged, isInCombat: %d", isInCombat);
		} 
	else if ([combatMatch isEqualToString:@"Combat Off"] && isInCombat) 
		{
		isInCombat = NO;
		NSLog(@"Combat Off, isInCombat: %d", isInCombat);
		shouldCheckForTargets = YES;
		}
//		[self checkForTargets:nil];
//	}
	
//	
//	
//	[regExObj release];
//	NSString *youNotice = [NSString stringWithFormat:@"You notice (.+) here\\."];
//	regExObj = [[OFRegularExpression alloc] initWithString:youNotice];
//	match = [regExObj matchInString:[attributedString string]];
//	//		NSLog(@"MATCH: %@", match);
//	if (match) {
//		//			NSLog(@"COUNT: %d", [regExObj2 subexpressionCount]);
//		NSString *itemList = [match subexpressionAtIndex:0];
//		NSArray *items = [itemList componentsSeparatedByString:@", "];
//		//			NSLog(@"TARGETS: %@", targets);
//		for (NSString *item in items) {
//			OFRegularExpression *itemSearch = [[OFRegularExpression alloc] initWithString:@"platinum pieces|gold crown|silver noble"];
//			OFRegularExpressionMatch *itemMatch = [itemSearch matchInString:item];
//			
//			if (itemMatch) {
////				NSLog(@"Found : %@", item);
//				NSString *command = [NSString stringWithFormat:@"get %@", item];
//				[self performSelectorOnMainThread:@selector(sendCommand:) withObject:command waitUntilDone:NO];				
//				itemMatch = [itemMatch nextMatch];
//			}
//		}
//	}
	
	NSString *somethingCameIn = [[attributedString string] stringByMatching:@"into the room from"];
	if (somethingCameIn) 
		{
		shouldCheckForTargets = YES;
		}
	
//	NSString *intoTheRoom = [NSString stringWithFormat:@"into the room from"];
//	[regExObj release];
//	regExObj = [[OFRegularExpression alloc] initWithString:intoTheRoom];
//	match = [regExObj matchInString:[attributedString string]];
//	
//	if (match) {
////		NSLog(@"something moved into the room");
//		shouldCheckForTargets = YES;
////		[self checkForTargets:nil];
////		[self performSelectorOnMainThread:@selector(checkForTargets:) withObject:nil waitUntilDone:NO];
//	}
//
	NSArray *experienceMatches = [[attributedString string]  arrayOfCaptureComponentsMatchedByRegex:@"You gain (\\d*) experience."];
	
	if ([experienceMatches count]) 
		{
		isInCombat = NO;
		totalExperienceGained = totalExperienceGained + [[[experienceMatches lastObject] lastObject] integerValue];
		[experienceLabel setStringValue:[NSString stringWithFormat:@"Experience Gained: %d", totalExperienceGained]];
		}
//	[regExObj release];
//	NSString * usernamePrompt = @"Enter your User-ID:";
//	regExObj = [[OFRegularExpression alloc] initWithString:usernamePrompt];
//	match = [regExObj matchInString:[attributedString string]];
//	if (match)
//	{
//		[self performSelectorOnMainThread:@selector(sendCommand:) withObject:@"darius" waitUntilDone:NO];
//	}
//	
//	[regExObj release];
//	NSString * passwordPrompt = @"Enter your password:";
//	regExObj = [[OFRegularExpression alloc] initWithString:passwordPrompt];
//	match = [regExObj matchInString:[attributedString string]];
//	if (match)
//	{
//		[self performSelectorOnMainThread:@selector(sendCommand:) withObject:@"clerks" waitUntilDone:NO];
//	}
//	
//	[regExObj release];
//	NSString * continuePrompt = @"\\(C\\)ontinue\\?";
//	regExObj = [[OFRegularExpression alloc] initWithString:continuePrompt];
//	match = [regExObj matchInString:[attributedString string]];
//	if (match)
//	{
//		[self performSelectorOnMainThread:@selector(sendCommand:) withObject:@"q" waitUntilDone:NO];
//	}

//	[regExObj release];
//	NSString * menuPrompt = @"Make your selection: \\(A,E,M,P,R,\\? for help, or X to exit\\):";
//	regExObj = [[OFRegularExpression alloc] initWithString:menuPrompt];
//	match = [regExObj matchInString:[attributedString string]];
//	if (match)
//	{
//		[self performSelectorOnMainThread:@selector(sendCommand:) withObject:@"m" waitUntilDone:NO];
//	}
//
//	[regExObj release];
//	NSString * mudPrompt = @"E] . Enter the Realm";
//	regExObj = [[OFRegularExpression alloc] initWithString:mudPrompt];
//	match = [regExObj matchInString:[attributedString string]];
//	if (match)
//	{
//		[self performSelectorOnMainThread:@selector(sendCommand:) withObject:@"e" waitUntilDone:NO];
//	}
//
//	
	if (shouldCheckForTargets)
		[self checkForTargets:nil];
//	
	[backgroundPool release];
	
}

- (void)attackTarget:(NSString *)aTarget
{
	if (isAutoAttacking) {
//		isInCombat = YES;
		[self sendCommand:[NSString stringWithFormat:@"attack %@", aTarget]];		
	}
//	NSLog(@"Attack %@", aTarget);
}

- (IBAction)send:(id)sender
{
	[self sendCommand:[inputTextField stringValue]];
	[inputTextField setStringValue:@""];
//	NSLog(@"%u", len);
}

- (void)sendCommand:(NSString *)aCommand
{
	NSString *input = [NSString stringWithFormat:@"%@%c%c",aCommand, 13, 10];
	NSData *data = [input dataUsingEncoding:NSASCIIStringEncoding];
	unsigned int len = [input length];
	uint8_t buf[len];
	(void)memcpy(buf, [data bytes] , len);
	len = [oStream write:(const uint8_t *)buf maxLength:len];
}

- (void)attributedString:(NSMutableAttributedString *)aString withCode:(NSInteger)aCode forRange:(NSRange)aRange
{
//	NSDictionary *dict = nil;
	
	switch (aCode) {
		case 0:{
			// TODO:all attributes off
			break;
		}
		case 1: {
			// TODO: bold on
			break;
		}
		case 4: {
			// TODO: Underscore (on monochrome display adapter only)
			break;
		}
		case 5:{
			// TODO: blink on
			break;
		}
		case 7: {
			// TODO: Reverse video on
			break;
		}
		case 8: {
			// TODO: Concealed On
			break;
		}
		case 30: {
			// black foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:aRange];
			break;
		}
		case 31: {
			// Red foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:aRange];
			break;
		}
		case 32: {
			// Green foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:aRange];
			break;
		}
		case 33: {
			// Yellow foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor yellowColor] range:aRange];
			break;
		}
		case 34: {
			// Blue foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:aRange];
			break;
		}
		case 35: {
			//Magenta Foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor magentaColor] range:aRange];
			break;
		} 
		case 36: {
			// Cyan foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor cyanColor] range:aRange];
			break;
		} 
		case 37: {
			//white foreground
			[aString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:aRange];
			break;
		}
		case 40: {
			// TODO: black background
			break;
		}
		case 41: {
			// TODO: Red background
			break;
		}
		case 42: {
			// TODO: Green background
			break;
		}
		case 43: {
			// TODO: Yellow background
			break;
		}
		case 44: {
			// TODO: Blue background
			break;
		}
		case 45: {
			// TODO Magenta background
			break;
		} 
		case 46: {
			// TODO: Cyan background
			break;
		} 
		case 47: {
			// TODO: white background
			break;
		}
			
		default:
			break;
	}
//	return dict;
}

- (IBAction)getAllItems:(id)sender
{
	[self sendCommand:@""];
//	NSString *youNotice = [NSString stringWithFormat:@"You notice (.+) here\\."];
//	OFRegularExpression *regExObj = [[OFRegularExpression alloc] initWithString:youNotice];
//	OFRegularExpressionMatch *match = [regExObj matchInString:lastInput];
//	//		NSLog(@"MATCH: %@", match);
//	if (match) {
//		//			NSLog(@"COUNT: %d", [regExObj2 subexpressionCount]);
//		NSString *itemList = [match subexpressionAtIndex:0];
//		NSArray *items = [itemList componentsSeparatedByString:@","];
//		//			NSLog(@"TARGETS: %@", targets);
//		for (NSString *item in items) {
//			NSString *command = [NSString stringWithFormat:@"get %@", item];
//			[self sendCommand:command];				
//		}
//	}
	
}

- (IBAction)equipAllItems:(id)sender
{	
	[self sendCommand:@"i"];
//	NSString *youAreCarrying = [NSString stringWithFormat:@"You are carrying (.+) keys."];
//	OFRegularExpression *regExObj = [[OFRegularExpression alloc] initWithString:youAreCarrying];
//	OFRegularExpressionMatch *match = [regExObj matchInString:lastInput];
//	NSLog(@"last input: %@", lastInput);
//	//		NSLog(@"MATCH: %@", match);
//	NSLog(@"you are carrying : %@", [match matchString]);
//	if (match) {
//		//			NSLog(@"COUNT: %d", [regExObj2 subexpressionCount]);
//		NSString *itemList = [match subexpressionAtIndex:0];
//		NSArray *items = [itemList componentsSeparatedByString:@","];
//		//			NSLog(@"TARGETS: %@", targets);
//		for (NSString *item in items) {
//			NSString *command = [NSString stringWithFormat:@"equip %@", item];
//			[self sendCommand:command];				
//		}
//	}
	
}	

#pragma mark -


- (void) dealloc
{
	[hostAddressTextField release];
	[portTextField release];
	[inputTextField release];
	[experienceLabel release];

	[outputTextView release];
	[super dealloc];
}


@end
