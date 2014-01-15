//
//  NSXMLParser+ReactiveCocoa.m
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

#import "NSXMLParser+ReactiveCocoa.h"
#import "NSXMLParserRACDelegate.h"
#import "NSXMLParserRACElement.h"

#import <ReactiveCocoa.h>

@implementation NSXMLParser (ReactiveCocoa)

+ (RACSignal *)rac_parseURL:(NSURL *)url
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        return [[RACScheduler scheduler] schedule:^{
            NSXMLParserRACDelegate * delegate = [[NSXMLParserRACDelegate alloc] init];
            [delegate.elementParsed subscribe:subscriber];
            
            NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
            parser.delegate = delegate;
            [parser parse];
        }];
    }];
}

// Parsing algorythm inspired by http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter
+ (RACSignal *)rac_dictionaryFromURL:(NSURL *)url elementFilter:(ElementFilterBlock)filterBlock
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        __block NSMutableArray *stack = [@[ [@{} mutableCopy] ] mutableCopy];
        __block NSXMLParserRACElement *currentElement;
        
        [[[NSXMLParser rac_parseURL:url] filter:^BOOL(NSXMLParserRACElement *element) {
            // If provided delegate to filterBlock to determine which elements to ignore
            return filterBlock ? filterBlock(element.name) : YES;
        
        }] subscribeNext:^(NSXMLParserRACElement *element) {
            if (element.phase == NSXMLParserRACElementPhaseOpen)
            {
                NSMutableDictionary *parent = [stack lastObject];
                NSMutableDictionary *child = [@{} mutableCopy];
                
                if ([element.attributes count])
                {
                    for (NSString *key in [element.attributes allKeys]) {
                        child[key] = element.attributes[key];
                    }
                }
                
                id existing = parent[element.name];
                if (existing)
                {
                    NSMutableArray *array = nil;
                    if ([existing isKindOfClass:[NSMutableArray class]]) {
                        array = existing;
                    }
                    else
                    {
                        array = [@[] mutableCopy];
                        [array addObject:existing];
                        
                        parent[element.name] = array;
                    }
                    
                    [array addObject:child];
                }
                else {
                    parent[element.name] = child;
                }
                
                [stack addObject:child];
            }
            
            if (element.phase == NSXMLParserRACElementPhaseData) {
                currentElement = element;
            }
            
            if (element.phase == NSXMLParserRACElementPhaseClose)
            {
                NSMutableDictionary *current = [stack lastObject];
                if (currentElement.body)
                {
                    NSString *sanitized = [currentElement.body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (sanitized && ![sanitized isEqualToString:@""]) {
                        current[@"text"] = sanitized;
                    }
                }
                
                [stack removeLastObject];
            }
            
        } error:^(NSError *error) {
            [subscriber sendError:error];
            
        } completed:^{
            if ([stack count] > 0) [subscriber sendNext:stack[0]];
            [subscriber sendCompleted];
        }];
        
        return [RACDisposable disposableWithBlock:^{
            stack = nil;
            currentElement = nil;
        }];
    }];
}

@end
