//
//  MyDocument.h
//  MacMud
//
//  Created by Mike Pattee on 7/2/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface MyDocument : NSDocument <NSStreamDelegate>
{
	NSTextField *hostAddressTextField;
	NSTextField *portTextField;
	NSTextField *inputTextField;
	
	NSTextView *outputTextView;
	
	NSInputStream *iStream;
	NSOutputStream *oStream;
	
	NSMutableData *_data;
	NSNumber *bytesRead;
	NSInteger byteIndex;
	
	NSString *lastInput;
	
	BOOL isInCombat;
	BOOL isAutoAttacking;
	
	NSTimer *checkForTargetsTimer;
	NSTextField *experienceLabel;
	NSInteger totalExperienceGained;
}

@property (nonatomic, retain) IBOutlet NSTextField *hostAddressTextField;
@property (nonatomic, retain) IBOutlet NSTextField *portTextField;
@property (nonatomic, retain) IBOutlet NSTextField *inputTextField;

@property (nonatomic, copy) NSString *lastInput;

@property (nonatomic, retain) IBOutlet NSTextView *outputTextView;

@property (nonatomic, retain) IBOutlet NSTextField *experienceLabel;

- (IBAction)connect:(id)sender;
- (void)processIncoming;
- (void)respondInBackgroundToInput:(NSDictionary *)anInputDictionary;
- (IBAction)send:(id)sender;
- (void)sendCommand:(NSString *)aCommand;
- (void)attackTarget:(NSString *)aTarget;
- (void)attributedString:(NSMutableAttributedString *)aString withCode:(NSInteger)aCode forRange:(NSRange)aRange;

- (void)checkForTargets:(NSTimer *)theTimer;
- (IBAction)toggleAutoAttack:(id)sender;

- (IBAction)getAllItems:(id)sender;
- (IBAction)equipAllItems:(id)sender;
@end
