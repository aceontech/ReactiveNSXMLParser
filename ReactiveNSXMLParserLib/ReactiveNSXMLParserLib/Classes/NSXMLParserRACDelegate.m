//
//  NSXMLParserRACDelegate.m
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

#import "NSXMLParserRACDelegate.h"
#import "NSXMLParserRACElement.h"

#import <ReactiveCocoa.h>

@interface NSXMLParserRACDelegate()
@property (nonatomic,strong) NSXMLParserRACElement *currentElement;
@end

@implementation NSXMLParserRACDelegate

- (RACSubject *)elementParsed
{
    if (!_elementParsed) {
        _elementParsed = [RACSubject subject];
    }
    return _elementParsed;
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [self.elementParsed sendCompleted];
}

/**
 * Called each time an element is 'opened'.
 * Initializes self.currentElement with an instance of NSXMLParserRACElement.
 * Notifies subscribers.
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.currentElement = ({
        NSXMLParserRACElement *e = [[NSXMLParserRACElement alloc] init];
        e.name = elementName;
        e.phase = NSXMLParserRACElementPhaseOpen;
        e.attributes = attributeDict;
        e;
    });
    
    [self.elementParsed sendNext:self.currentElement];
}

/**
 * Called each time an element is 'closed'
 * Notifies subscribers:
 *  - in case the 'body' property is read to read
 *  - in case the element is closed
 */
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
{
    // Deliver data & close current element
    if ([self.currentElement.name isEqualToString:elementName])
    {
        self.currentElement.phase = NSXMLParserRACElementPhaseData;
        [self.elementParsed sendNext:self.currentElement];
        
        self.currentElement.phase = NSXMLParserRACElementPhaseClose;
        [self.elementParsed sendNext:self.currentElement];
    }
    
    // Close previous element
    else
    {
        [self.elementParsed sendNext:({
            NSXMLParserRACElement *e = [[NSXMLParserRACElement alloc] init];
            e.name = elementName;
            e.phase = NSXMLParserRACElementPhaseClose;
            e;
        })];
    }
}

/** 
 * Called each time a run of text is read from the current element.
 * Text is appended to the 'body' property.
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.currentElement.body appendString:string];
}

/**
 * Called each time a CDATA block is encountered.
 * Decodes the binary CDATA represenation and appends it to the 'body' property.
 */
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    [self.currentElement.body appendString:[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding]];
}

/**
 * Called whenever a parser error occurs.
 * Simply notifies subscribers.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [self.elementParsed sendError:parseError];
}

@end
