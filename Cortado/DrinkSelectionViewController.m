#import <ReactiveCocoa/ReactiveCocoa.h>

#import "UINavigationController+ReactiveCocoa.h"

#import "Beverage.h"
#import "DrinkCategory.h"
#import "DrinkCategoryList.h"
#import "DrinkSubtype.h"
#import "DrinkSubtypeSelectionViewController.h"
#import "DrinkType.h"

#import "DrinkSelectionViewController.h"

static NSString * const CellIdentifier = @"cell";

@interface DrinkSelectionViewController ()

@property (nonatomic, strong) NSArray *categories;

@end

@implementation DrinkSelectionViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (!self) return nil;

    _selectedDrinkSignal = [RACSubject subject];

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.categories = [[[DrinkCategoryList alloc] initWithDefaultList] categories];


    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:CellIdentifier];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Check" style:UIBarButtonItemStylePlain target:UIApplication.sharedApplication.delegate action:@selector(checkCurrentLocation)];

}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    DrinkCategory *category = self.categories[indexPath.section];
    DrinkType *type = category.drinkTypes[indexPath.row];
    cell.textLabel.text = type.name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DrinkCategory *category = self.categories[indexPath.section];
    DrinkType *type = category.drinkTypes[indexPath.row];

    RACSignal *subtypeSignal;
    if (type.subtypes.count == 1) {
        subtypeSignal = [RACSignal return:type.subtypes.firstObject];
    } else {
        DrinkSubtypeSelectionViewController *drinkVC = [[DrinkSubtypeSelectionViewController alloc] initWithSubtypes:type.subtypes];
        subtypeSignal = [[[self.navigationController rac_pushViewController:drinkVC animated:YES]
            concat:drinkVC.subtypeSelectedSignal]
            take:1];
    }

    [[subtypeSignal
        map:^id(DrinkSubtype *subtype) {
            return [[Beverage alloc] initWithName:type.name
                                          subtype:subtype.name
                                         caffeine:subtype.caffeine];
        }]
        subscribeNext:^(Beverage *drink) {
            [_selectedDrinkSignal sendNext:drink];
        }];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.categories[section] name];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.categories.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DrinkCategory *category = self.categories[section];
    return category.drinkTypes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
}

@end