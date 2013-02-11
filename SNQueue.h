//
//  SNQueue.h
//  Alien Tower
//
//  Created by Asad Khan on 10/02/2013.
//
//

/*
 * Custom Objective C Implementation of Queue Data Structure
 * For more information Visit the wiki page below.
 * http://en.wikipedia.org/wiki/Queue_(data_structure)
 *
 */

#import <Foundation/Foundation.h>


/**
 Composition is choosen over inheritance or Categories
 NSMutableArray is used an internal data structure
 */
@interface SNQueue : NSObject




/**
 Public methods
 */
- (void)push:(id)item;
- (id) pop;
- (id) peek;
- (NSUInteger)count;

@end
