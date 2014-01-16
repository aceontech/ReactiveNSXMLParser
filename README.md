# ReactiveNSXMLParser

ReactiveCocoa extensions for NSXMLParser: A concise, stream-based API for parsing XML with NSXMLParser.

[![Build Status](https://travis-ci.org/aceontech/ReactiveNSXMLParser.png?branch=master)](https://travis-ci.org/aceontech/ReactiveNSXMLParser)

Defines a wrapper around [NSXMLParserDelegate](https://developer.apple.com/library/ios/documentation/cocoa/reference/NSXMLParserDelegate_Protocol/Reference/Reference.html), obsoleting the need for implementing fussy delegate methods.
Apply any ReactiveCocoa magic you want (see [NSXMLParserRACElement](https://github.com/aceontech/ReactiveNSXMLParser/blob/master/ReactiveNSXMLParserLib/ReactiveNSXMLParserLib/Classes/NSXMLParserRACElement.h)):

```objc
#import "NSXMLParser+ReactiveCocoa.h"

[[NSXMLParser rac_parseURL:url] subscribeNext:^(NSXMLParserRACElement *element) {
	// Each element is passed as it's read
	// TODO: Handle element
	
} error:^(NSError *error) {
	// TODO: Handle error
	
} completed:^{
	// TODO: Handle completion event
}];
```

 

## Usage examples

### Convert RSS feeds to NSDictionary/Value Objects

The following ReactiveCocoa snippet will load each XML file sequentially, parse them one 
by one and convert each feed into a custom object (any value object or NSDictionary of 
your choosing) (based on [this unit test](https://github.com/aceontech/ReactiveNSXMLParser/blob/master/ReactiveNSXMLParserLib/ReactiveNSXMLParserLibTests/ReactiveNSXMLParserLibTests.m#L119)).

```objc
#import "NSXMLParser+ReactiveCocoa.h"

// Only parse element name from this list
NSSet *elementFilter = [NSSet setWithArray:@[@"title", @"itunes:author", @"enclosure", @"pubDate", @"link", // General
											 @"image", @"width", @"height", @"url",                         // Album art
											 @"item", @"itunes:subtitle", @"itunes:summary"]];              // Items

// Define filter block here to be used with each feed
ElementFilterBlock filterBlock = ^BOOL(NSString *elementName) {
	return [elementFilter containsObject:elementName];
};

// Store signals for each parse job in this array.
NSArray *signals = @[[NSXMLParser rac_dictionaryFromURL:[NSURL URLWithString:@"http://feeds.twit.tv/ww.xml"] elementFilter:self.filterBlock],
					 [NSXMLParser rac_dictionaryFromURL:[NSURL URLWithString:@"http://feeds.twit.tv/sn.xml"] elementFilter:self.filterBlock]];

// [RACSignal -concat] creates a list of aforementioned signals an executes
// them *sequentially*. If you desire parallel execution, you could use one of
// the [RACSignal -conmbine..] methods.
[[[[RACSignal concat:signals] map:^NSDictionary*(NSDictionary *result) {
	// The 'result' dictionary will contain the raw object graph for the XML
	
	// [RACSignal -map:] provides a hook for you to transform this NSDictionary into any
	// data type you want:
	Podcast *podcast = [[Podcast alloc] init];
	podcast.title = [result valueForKeyPath:@"title.text"];
	
	return podcast;
	
}] collect] subscribeNext:^(NSArray *podcasts) {
	// The 'podcasts' array contains each Podcast* object as mapped in the previous block
	// [RACSignal -collect:] aggregates all values into a single NSArray.
	
	// TODO: Use the data
	
} error:^(NSError *error) {
	// TODO: Do something with this error
}];
```

### DIY Parsing

You can also parse XML yourself, using the `[RACSignal +rac_parseURL:]` method. This is a 
ReactiveCocoa wrapper around [NSXMLParserDelegate](https://developer.apple.com/library/ios/documentation/cocoa/reference/NSXMLParserDelegate_Protocol/Reference/Reference.html). 
See [NSXMLParser+ReactiveCocoa.m](https://github.com/aceontech/ReactiveNSXMLParser/blob/master/ReactiveNSXMLParserLib/ReactiveNSXMLParserLib/Classes/NSXMLParser%2BReactiveCocoa.m#L51) 
for an example implementation. 

In short, this is how to could use the `-rac_parseURL:` API:

```objc
#import "NSXMLParser+ReactiveCocoa.h"

[[[NSXMLParser rac_parseURL:url] filter:^BOOL(NSXMLParserRACElement *element) {
	// Filter non-applicable elements (optional)
	return YES;
	
}] subscribeNext:^(NSXMLParserRACElement *element) {
	// Each time an element is processed, it will be passed here.
	if (element.phase == NSXMLParserRACElementPhaseOpen)
	{
		// Element tag was opened
		// TODO: Handle this
	}
	
	if (element.phase == NSXMLParserRACElementPhaseData) 
	{
		// Element's text or CData was read
		// TODO: Use element.body
	}
	
	if (element.phase == NSXMLParserRACElementPhaseClose)
	{
		// Element was closed
		// TODO: Handle this
	}
	
} error:^(NSError *error) {
	// TODO: Handle error
	
} completed:^{
	// TODO: Handle completion event
}];
```