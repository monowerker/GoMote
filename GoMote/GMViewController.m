//
//  GMViewController.m
//  GoMote
//
//  Created by Daniel Ericsson on 2013-11-15.
//  Copyright (c) 2013 MONOWERKS. All rights reserved.
//

#import "GMViewController.h"
// -- Controllers
#import "ESTBeaconManager.h"
// -- Utils
#import "MWLog.h"

@interface GMViewController () <UITableViewDataSource, UITableViewDelegate, ESTBeaconManagerDelegate>

@property (nonatomic,  readonly, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, readwrite, strong) ESTBeaconRegion *wildcardRegion;
@property (nonatomic,  readonly, strong) UITableView *tableView;
@property (nonatomic, readwrite, strong) NSDictionary *sections;
@property (nonatomic, readwrite, strong) NSMapTable *proximityForBeacon;

@end

static NSString *reuseIdentifier = @"GMBeaconCellIdentifier";

typedef NS_ENUM(NSInteger, GMSectionIndex) {
	GMSectionIndexImmediate,
	GMSectionIndexNear,
	GMSectionIndexFar,
	GMSectionIndexUnknown,
};

@implementation GMViewController

@synthesize tableView = _tableView;
@synthesize beaconManager = _beaconManager;


#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sections = @
    {
        @"Immediate" : [[NSMutableOrderedSet alloc] init],
        @"Near" : [[NSMutableOrderedSet alloc] init],
        @"Far" : [[NSMutableOrderedSet alloc] init],
    };
    
    self.proximityForBeacon = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsStrongMemory|
                                                                  NSPointerFunctionsObjectPointerPersonality)
                                                    valueOptions:(NSPointerFunctionsStrongMemory|
                                                                  NSPointerFunctionsObjectPersonality)];
    
    self.wildcardRegion = [[ESTBeaconRegion alloc] initRegionWithIdentifier:@"GMWildCardRegion"];
    [self.view addSubview:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.beaconManager startRangingBeaconsInRegion:self.wildcardRegion];
}


#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    self.tableView.frame = CGRectMake(0, self.topLayoutGuide.length,
                                      self.view.bounds.size.width,
                                      self.view.bounds.size.height);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private properties

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
        _tableView.allowsSelection = NO;
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifier];
    }
    
    return _tableView;
}

- (ESTBeaconManager *)beaconManager {
    if (!_beaconManager) {
        _beaconManager = [[ESTBeaconManager alloc] init];
        _beaconManager.delegate = self;
        _beaconManager.avoidUnknownStateBeacons = YES;
    }
    
    return _beaconManager;
}


#pragma mark - SectionKey lookup

- (NSString *)sectionKeyForSection:(GMSectionIndex)section {
    NSString *key;
    switch (section) {
        case GMSectionIndexImmediate:
            key = @"Immediate";
            break;
        case GMSectionIndexNear:
            key = @"Near";
            break;
        case GMSectionIndexFar:
            key = @"Far";
            break;
        case GMSectionIndexUnknown:
            key = @"Unknown";
            break;
        default:
            key = nil;
            break;
    }
    
    return key;
}

- (NSString *)sectionKeyForProximity:(CLProximity)proximity {
    NSString *key;
    switch (proximity) {
        case CLProximityImmediate:
            key = @"Immediate";
            break;
        case CLProximityNear:
            key = @"Near";
            break;
        case CLProximityFar:
            key = @"Far";
            break;
        case CLProximityUnknown:
            key = @"Unknown";
            break;
        default:
            key = nil;
            break;
    }
    
    return key;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.sections allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self sectionKeyForSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[[self sectionKeyForSection:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    id model = [self.sections[[self sectionKeyForSection:indexPath.section]] objectAtIndex:indexPath.row];

    return [self configureCell:cell forIndexPath:indexPath withModel:model];
}

- (UITableViewCell *)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath withModel:(id)model {
    cell.textLabel.text = [NSString stringWithFormat:@"%@", [(NSUUID *)[(CLBeacon *)[model ibeacon] proximityUUID] UUIDString]];
    
    return cell;
}


#pragma mark - ESTBeaconManagerDelegate

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region {
    static BOOL tableViewInvalid;
    
    for (ESTBeacon *beacon in beacons) {
        CLProximity proximity = NSIntegerMax;
        id proximityValue = [self.proximityForBeacon objectForKey:beacon];
        if (proximityValue && [proximityValue respondsToSelector:@selector(integerValue)]) {
            proximity = [proximityValue integerValue];
        }
        
        if (proximity != beacon.ibeacon.proximity) {
            if (proximity <= CLProximityFar) {
                [self.sections[[self sectionKeyForProximity:proximity]] removeObject:beacon];
            }
            
            [self.sections[[self sectionKeyForProximity:beacon.ibeacon.proximity]] addObject:beacon];
            [self.proximityForBeacon setObject:[NSNumber numberWithInteger:beacon.ibeacon.proximity] forKey:beacon];
            
            tableViewInvalid = YES;
        }
    }
    
    if (tableViewInvalid) {
        [self.tableView reloadData];
        tableViewInvalid = NO;
    }
}

@end
