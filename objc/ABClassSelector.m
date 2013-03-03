//
//  ABClassSelector.m
//  ABExample
//
//  Created by Sam Morrison on 3/1/13.
//  Copyright (c) 2013 Sam Morrison. All rights reserved.
//

#import "ABClassSelector.h"

@implementation ABClassSelector

int AB_CLASS_INDEX = 1;

+ (id)alloc
{
    return [[[self classes] objectAtIndex:AB_CLASS_INDEX] alloc];
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[[self classes] objectAtIndex:AB_CLASS_INDEX] allocWithZone:zone];
}

+ (NSArray *)classes
{
    return nil;
}

@end
