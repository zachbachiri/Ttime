//
//  TTMBTAService.m
//  Ttime
//
//  Created by Andrew Barba on 9/24/13.
//  Copyright (c) 2013 Andrew Barba. All rights reserved.
//

#import "TTMBTAService.h"
#import "TTTimeService.h"

@interface TTMBTAService() {
    NSArray *_redLineTrains;
    NSArray *_greenLineTrains;
    NSArray *_blueLineTrains;
    NSArray *_orangeLineTrains;
    NSArray *_silverLineTrains;
}

@property (nonatomic, strong) CLLocation *lastKnownLocation;

@end

@implementation TTMBTAService

- (NSArray *)redLineTrains
{
    return _redLineTrains;
}

- (NSArray *)greenLineTrains
{
    return _greenLineTrains;
}

- (NSArray *)blueLineTrains
{
    return _blueLineTrains;
}

- (NSArray *)orangeLineTrains
{
    return _orangeLineTrains;
}

- (NSArray *)silverLineTrains
{
    return _silverLineTrains;
}

- (void)setLastKnownLocation:(CLLocation *)lastKnownLocation
{
    if (![_lastKnownLocation isEqual:lastKnownLocation]) {
        _lastKnownLocation = lastKnownLocation;
    }
}

#pragma mark - Update Data

- (void)updateAllDataForLocation:(CLLocation *)location onComplete:(TTBlock)complete
{
    if (!location) return;
    
    self.lastKnownLocation = location;
    
    NSArray *lines = @[ _greenLineTrains, _orangeLineTrains, _redLineTrains, _blueLineTrains, _silverLineTrains ];
    
    NSMutableArray *stops = [NSMutableArray array];
    
    for (NSArray *line in lines) {
        for (TTTrain *train in line) {
            TTStop *stop = [train closestStopToLocation:location];
            [stops addObject:stop];
        }
    }
    
    __block NSUInteger remaining = stops.count;
    
    for (TTStop *stop in stops) {
        [[TTTimeService sharedService] fetchTTimeForStop:stop onCompletion:^(TTTime *time, NSError *error){
            remaining--;
            if (remaining == 0 && complete) {
                complete();
            }
        }];
    }
}

#pragma mark - Load Data

- (void)_setTrainArray:(NSArray *)trains forKey:(NSString *)key
{
    if ([key isEqualToString:@"red"])    _redLineTrains = trains;
    if ([key isEqualToString:@"orange"]) _orangeLineTrains = trains;
    if ([key isEqualToString:@"blue"])   _blueLineTrains = trains;
    if ([key isEqualToString:@"green"])  _greenLineTrains = trains;
    if ([key isEqualToString:@"silver"]) _silverLineTrains = trains;
}

- (void)_initData:(NSDictionary *)data
{
    [data enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *trainsArray, BOOL *done){
        NSMutableArray *trains = [NSMutableArray array];
        [trainsArray enumerateObjectsUsingBlock:^(NSDictionary *trainDict, NSUInteger index, BOOL *stop){
            TTTrain *train = [TTTrain mbtaObjectFromDictionary:trainDict];
            [trains addObject:train];
        }];
        [self _setTrainArray:trains forKey:key];
    }];
}

#pragma mark - Initialization

- (id)_initPrivate
{
    self = [super init];
    if (self) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"stops" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        [self _initData:dict];
    }
    return self;
}

+ (instancetype)sharedService
{
    static id service = nil;
    TT_DISPATCH_ONCE(^{
        service = [[self alloc] _initPrivate];
    });
    return service;
}

@end
