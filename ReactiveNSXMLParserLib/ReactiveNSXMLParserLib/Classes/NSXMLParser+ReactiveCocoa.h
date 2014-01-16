//
//  NSXMLParser+ReactiveCocoa.h
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

@class RACSignal;
@class NSXMLParserRACElement;

typedef BOOL (^ElementFilterBlock)(NSString *elementName);

/**
 * This category provides a reactive interface to the normally delegate-based 
 * NSXMLParser. 
 */
@interface NSXMLParser (ReactiveCocoa)

/**
 * Provides a Stream-based/Reactive API for [NSXMLParser -parse:]. The 'next' handler will receive
 * an NSXMLParserRACElement objects as the XML document is traversed (element by element, top-down).
 * There are 3 phases:
 *  - NSXMLParserRACElementPhaseData: The elements 'body' property is ready (string)
 *  - NSXMLParserRACElementPhaseOpen: The tag was opened
 *  - NSXMLParserRACElementPhaseCloseL The tag was closed
 * This enables you to parse the whole document, or just parts of it.
 *
 * @param url NSURL The URL to fetch and process
 * @return RACSignal 'next' parameter type is NSXMLParserRACElement
 */
+ (RACSignal *)rac_parseURL:(NSURL *)url;

/**
 * Parses an XML file at a URL directly into a dictionary.
 *
 * @param url NSURL The URL to fetch and process
 * @param elementFilter ElementFilterBlock (optional) Enables filtering on an element-name level
 * @return RACSignal Will 'next' exactly once, with a NSDictionary parameter
 */
+ (RACSignal *)rac_dictionaryFromURL:(NSURL *)url
                       elementFilter:(ElementFilterBlock)filterBlock;

/**
 * Parses an XML file from a binary blob.
 * See -rac_dictionaryFromURL:elementFilter:
 */
+ (RACSignal *)rac_dictionaryFromData:(NSData *)data
                        elementFilter:(ElementFilterBlock)filterBlock;

/**
 * Convenience wrapper for +rac_dictionaryFromData. Converts NSString to NSData.
 * BLOCKING!
 * See -rac_dictionaryFromURL:elementFilter:
 */
+ (RACSignal *)rac_dictionaryFromString:(NSString *)string
                          elementFilter:(ElementFilterBlock)filterBlock;

@end
