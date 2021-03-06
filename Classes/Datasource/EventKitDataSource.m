/*
 * Copyright (c) 2010 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "EventKitDataSource.h"
#import <EventKit/EventKit.h>

static BOOL IsDateBetweenInclusive(NSDate *date, NSDate *begin, NSDate *end)
{
  return [date compare:begin] != NSOrderedAscending && [date compare:end] != NSOrderedDescending;
}

@interface EventKitDataSource ()
- (NSArray *)eventsFrom:(NSDate *)fromDate to:(NSDate *)toDate;
- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate;
@end

@implementation EventKitDataSource

+ (EventKitDataSource *)dataSource
{
  return [[[[self class] alloc] init] autorelease];
}

- (id)init
{
  if ((self = [super init])) {
    eventStore = [[EKEventStore alloc] init];
    events = [[NSMutableArray alloc] init];
    items = [[NSMutableArray alloc] init];
    eventStoreQueue = dispatch_queue_create("ag.calendar", NULL);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventStoreChanged:) name:EKEventStoreChangedNotification object:nil];
  }
  return self;
}

- (void)eventStoreChanged:(NSNotification *)note
{
  [[NSNotificationCenter defaultCenter] postNotificationName:KalDataSourceChangedNotification object:nil];
}

- (EKEvent *)eventAtIndexPath:(NSIndexPath *)indexPath
{
  return [items objectAtIndex:indexPath.row];
}

#pragma mark UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *identifier = @"MyCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (!cell) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
  }

  EKEvent *event = [self eventAtIndexPath:indexPath];
  cell.textLabel.text = event.title;
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [items count];
}

#pragma mark KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
    [events removeAllObjects];
    dispatch_async(eventStoreQueue, ^{
        NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:fromDate endDate:toDate calendars:nil];
        NSArray *matchedEvents = [eventStore eventsMatchingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"Fetched %d events in %f seconds", [matchedEvents count], -1.f * [fetchProfilerStart timeIntervalSinceNow]);
            [events addObjectsFromArray:matchedEvents];
            [delegate loadedDataSource:self];
        });
    });
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
  // synchronous callback on the main thread
  return [[self eventsFrom:fromDate to:toDate] valueForKeyPath:@"startDate"];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
  // synchronous callback on the main thread
  [items addObjectsFromArray:[self eventsFrom:fromDate to:toDate]];
}

- (void)removeAllItems
{
  // synchronous callback on the main thread
  [items removeAllObjects];
}

#pragma mark -

-(BOOL)deleteEvent:(id)args
{
   // EKEvent *_event = [EKEvent eventWithEventStore:eventStore];
    return YES;
}

- (void)addEvent:(NSString *)name startDate:(NSDate *)startDate endDate:(NSDate *)endDate location:(NSString *)location notes:(NSString *)notes
{
    EKEvent *_event = [EKEvent eventWithEventStore:eventStore];
	_event.title = name;
	_event.startDate = [[[NSDate alloc] initWithTimeInterval:1200 sinceDate:startDate] autorelease];	
	_event.location = location;
    _event.notes = notes;
	_event.endDate = [[[NSDate alloc] initWithTimeInterval:1200 sinceDate:endDate] autorelease];
	
    [_event setCalendar:[eventStore defaultCalendarForNewEvents]];
    NSError *err = nil; 
    [eventStore saveEvent:_event span:EKSpanThisEvent error:&err];

}

- (NSArray *)eventsFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
  NSMutableArray *matches = [NSMutableArray array];
  for (EKEvent *event in events)
    if (IsDateBetweenInclusive(event.startDate, fromDate, toDate))
      [matches addObject:event];
  
  return matches;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EKEventStoreChangedNotification object:nil];
    [items release];
    [glob release];
    [events release];
    dispatch_sync(eventStoreQueue, ^{
        [eventStore release];
    });
    dispatch_release(eventStoreQueue);
    [super dealloc];
}

@end
