//
//  NSXMLParserRACElement.h
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

typedef NS_ENUM(NSInteger, NSXMLParserRACElementPhase) {
    NSXMLParserRACElementPhaseData = 0, // Element contains a valid self.body
    NSXMLParserRACElementPhaseOpen,     // Element was opened
    NSXMLParserRACElementPhaseClose     // Element was closed
};

@interface NSXMLParserRACElement : NSObject

/**
 * Defines which phase the parser is currently in.
 * See NSXMLParserRACElementPhase enum.
 */
@property (nonatomic) NSXMLParserRACElementPhase phase;

/**
 * The element's name. E.g. <title> becomes @"title".
 */
@property (nonatomic,copy) NSString *name;

/**
 * The element's body, which was read out as a string or CData block
 */
@property (nonatomic,strong) NSMutableString *body;

/**
 * The element's attributes
 */
@property (nonatomic,copy) NSDictionary *attributes;

@end
