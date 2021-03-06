//
//  AgCalendarView.m
//  AgCalendar
//
//  Created by Chris Magnussen on 01.10.11.
//  Copyright 2011 Appgutta DA. All rights reserved.
//

#import "AgCalendarView.h"
#import "TiUtils.h"
#import "Event.h"
#import "SQLDataSource.h"
#import "EventKitDataSource.h"
//#import <EventKit/EventKit.h>
//#import <EventKitUI/EventKitUI.h>

static id nilIsNull(id value) { return value ? value : [NSNull null]; }
static id zeroIsNull(int value) { return value ? @"true" : @"false"; }

@implementation AgCalendarView

@synthesize g;

-(KalViewController*)calendar
{
    if (calendar==nil)
    {
        g = [Globals sharedDataManager];
        calendar = [[KalViewController alloc] init];
        dataSource = [g.dbSource isEqualToString:@"coredata"] ? [[SQLDataSource alloc] init] : [[EventKitDataSource alloc] init];
        calendar.dataSource = dataSource;
        calendar.delegate = self;
        [self addSubview:calendar.view];
    }
    return calendar;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Send event details back to Titanium
    if ([self.proxy _hasListeners:@"event:clicked"]) {
        NSDictionary *eventDetails;
        if ([g.dbSource isEqualToString:@"coredata"]) {
            Event *event = [dataSource eventAtIndexPath:indexPath];
            eventDetails = [NSDictionary dictionaryWithObjectsAndKeys: 
                                    event.name, @"title", 
                                    event.location, @"location",
                                    event.attendees, @"attendees", 
                                    event.type, @"type",
                                    event.identifier, @"identifier",
                                    event.note, @"note", 
                                    event.startDate, @"startDate", 
                                    event.endDate, @"endDate",
                                    event.organizer, @"organizer",
                            nil];
        } else {
            EKEvent *event = [dataSource eventAtIndexPath:indexPath];
            eventDetails = [NSDictionary dictionaryWithObjectsAndKeys: 
                                    event.title, @"title", 
                                    event.location, @"location",
                                    event.startDate, @"startDate", 
                                    event.endDate, @"endDate",
                                    event.notes, @"notes",
                            nil];
        }
        
        NSDictionary *eventSelected = [NSDictionary dictionaryWithObjectsAndKeys: eventDetails, @"event", nil];
		[self.proxy fireEvent:@"event:clicked" withObject:eventSelected];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) 
    {
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    if (calendar!=nil)
    {
        [TiUtils setView:calendar.view positionRect:bounds];
    }
}

-(void)showPreviousMonth{}
-(void)showFollowingMonth{}
-(void)didSelectDate:(KalDate *)date{}

- (void)showAndSelectToday:(id)args
{
    [[self calendar] showAndSelectDate:[NSDate date]];
}

-(void)setColor_:(id)color
{
    UIColor *c = [[TiUtils colorValue:color] _color];
    KalViewController *s = [self calendar];
    s.view.backgroundColor = c;
}

-(void)dealloc
{
    [calendar release];
    [dataSource release];
    [super dealloc];
}

@end