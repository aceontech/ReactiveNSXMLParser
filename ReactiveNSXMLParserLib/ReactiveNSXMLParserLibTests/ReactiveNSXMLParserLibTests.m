//
//  ReactiveNSXMLParserLibTests.m
//
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Alex Manarpies
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <XCTest/XCTest.h>
#import <ReactiveCocoa.h>
#import <TRVSMonitor.h>

#import "NSXMLParser+ReactiveCocoa.h"

/**
 * Unit tests for NSXMLParser+ReactiveCocoa.
 *
 * A note on TRVSMonitor:
 * TRVSMonitor is a utility which blocks the current thread while tasks on another
 * thread continues to run. This allows the XCTestCase to remain running until
 * the async code completes.
 */
@interface ReactiveNSXMLParserLibTests : XCTestCase
@property (nonatomic,copy) ElementFilterBlock filterBlock;
@property (nonatomic,copy) NSString *xmlString;
@property (nonatomic,copy) NSData *xmlData;
@end

@implementation ReactiveNSXMLParserLibTests

- (void)setUp
{
    [super setUp];
    
    // Create a preset filter which rejects non-podcast related elements
    NSSet *elementFilter = [NSSet setWithArray:@[@"title", @"itunes:author", @"enclosure", @"pubDate", @"link", // General
                                                 @"image", @"width", @"height", @"url",                         // Album art
                                                 @"item", @"itunes:subtitle", @"itunes:summary"]];              // Items
    
    self.filterBlock = ^BOOL(NSString *elementName) {
        return [elementFilter containsObject:elementName];
    };
    
    // Some XML in string format
    self.xmlString = @"<rss><item><title>Test 1</title></item><item><title>Test 2</title></item></rss>";
    
    // Some XML in NSData format
    self.xmlData = [self.xmlString dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)tearDown
{
    // TODO
    [super tearDown];
}

#pragma mark - Tests

/**
 * Tests whether the Windows Weekly podcast feed is parsable.
 * Only parses a subset of elements (see self.filterBlock).
 * Requires an internet connection.
 */
- (void)testParseWindowsWeeklyFromURL
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    [[NSXMLParser rac_dictionaryFromURL:[NSURL URLWithString:@"http://feeds.twit.tv/ww.xml"] elementFilter:self.filterBlock] subscribeNext:^(NSDictionary *feed) {
        XCTAssertTrue([feed count] > 0, @"Feed should contain child nodes");
        
    } error:^(NSError *error) {
        XCTFail(@"%@", error);
        [monitor signal];
        
    } completed:^{
        [monitor signal];
    }];
    
    [monitor wait];
}

- (void)testParseWindowsWeeklyFromData
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    [[NSXMLParser rac_dictionaryFromData:self.xmlData elementFilter:self.filterBlock] subscribeNext:^(NSDictionary *feed) {
        XCTAssertTrue([feed count] > 0, @"Feed should contain child nodes");

    } error:^(NSError *error) {
        XCTFail(@"%@", error);
        [monitor signal];
        
    } completed:^{
        [monitor signal];
    }];
    
    [monitor wait];
}

- (void)testParseWindowsWeeklyFromString
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    [[NSXMLParser rac_dictionaryFromString:self.xmlString elementFilter:self.filterBlock] subscribeNext:^(NSDictionary *feed) {
        XCTAssertTrue([feed count] > 0, @"Feed should contain child nodes");
        
    } error:^(NSError *error) {
        XCTFail(@"%@", error);
        [monitor signal];
        
    } completed:^{
        [monitor signal];
    }];
    
    [monitor wait];
}

/**
 * Tests whether the Windows Weekly podcast feed is parsable without filters.
 * Requires an internet connection.
 */
- (void)testParseWindowsWeeklyNoFilter
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    [[NSXMLParser rac_dictionaryFromURL:[NSURL URLWithString:@"http://feeds.twit.tv/ww.xml"] elementFilter:nil] subscribeNext:^(NSDictionary *feed) {
        XCTAssertTrue([feed count] > 0, @"Feed should contain child nodes");
        
    } error:^(NSError *error) {
        XCTFail(@"%@", error);
        [monitor signal];
        
    } completed:^{
        [monitor signal];
    }];
    
    [monitor wait];
}

/**
 * Tests whether multiple feeds can be parsed in sequence.
 * Demonstrates how to map each NSDictionary into a different datatype and
 * collect these into a single NSArray.
 * Requires an internet connection.
 */
- (void)testParseMultipleFeeds
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    // Store signals for each parse job in this array.
    NSArray *signals = @[[NSXMLParser rac_dictionaryFromURL:[NSURL URLWithString:@"http://feeds.twit.tv/ww.xml"] elementFilter:self.filterBlock],
                         [NSXMLParser rac_dictionaryFromURL:[NSURL URLWithString:@"http://feeds.twit.tv/sn.xml"] elementFilter:self.filterBlock]];
    
    // [RACSignal -concat] creates a list of aforementioned signals an executes
    // them *sequentially*. If desire parallel execution, you could use one of
    // the [RACSignal -conmbine..] methods.
    [[[[RACSignal concat:signals] map:^NSDictionary*(NSDictionary *result) {
        // [RACSignal -map:] transforms the dictionary into the desired data type
        // (this happens to be another dictionary, for demonstration purposes.
        // It can be whichever class you wish, however.
        NSDictionary *podcast = @{@"title": [result valueForKeyPath:@"title.text"]};
        return podcast;
        
    }] collect] subscribeNext:^(NSArray *podcasts) {
        // [RACSignal -collect:] aggregates all values into a single NSArray.
        // This is where we'd generally hand the result back to any subscribers.
        
        // Quickly assert whether the NSArray contains the correct data..
        XCTAssertTrue([podcasts count] == 2, @"List should contain 2 podcasts");
        XCTAssertTrue(podcasts[0][@"title"] != nil, @"First podcast should contain a title");
        XCTAssertTrue(podcasts[1][@"title"] != nil, @"Second podcast should contain a title");
        
        // Note that these events come in on a background scheduler (thread/queue).
        // If you want these to arrive on the main queue, use [RACSignal -deliverOn:].
        [monitor signal];
        
    } error:^(NSError *error) {
        XCTFail(@"%@", error);
        [monitor signal];
    }];
    
    [monitor wait];
}

@end
