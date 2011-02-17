#import "KGOHomeScreenViewController.h"
#import "KGOModule.h"
#import "HomeModule.h"
#import "UIKit+KGOAdditions.h"
#import "SpringboardIcon.h"

#import "PersonDetails.h"

@interface KGOHomeScreenViewController (Private)

- (void)loadModules;
+ (GridSpacing)spacingWithArgs:(NSArray *)args;
+ (GridPadding)paddingWithArgs:(NSArray *)args;
+ (CGSize)maxLabelDimensionsForModules:(NSArray *)modules font:(UIFont *)font;

@end


@implementation KGOHomeScreenViewController

@synthesize primaryModules = _primaryModules, secondaryModules = _secondaryModules;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"DefaultTheme" ofType:@"plist"];
        NSDictionary *themeDict = [[NSDictionary alloc] initWithContentsOfFile:file];
        _preferences = [[themeDict objectForKey:@"HomeScreen"] retain];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
		NSString * file = [[NSBundle mainBundle] pathForResource:@"DefaultTheme" ofType:@"plist"];
        NSDictionary *themeDict = [[NSDictionary alloc] initWithContentsOfFile:file];
        _preferences = [[themeDict objectForKey:@"HomeScreen"] retain];
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    
    [self loadModules];
    
    if ([self showsSearchBar]) {
        //_searchBar = [[KGOSearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        _searchBar = [[KGOSearchBar defaultSearchBarWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)] retain];
        _searchBar.placeholder = [NSString stringWithString:@"Search Harvard Mobile"];
        [self.view addSubview:_searchBar];
    }
}

- (void)viewDidLoad {
    UIImage *background = [self backgroundImage];
    if (background) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:background];
    }
    
	UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];	
	[[self navigationItem] setBackBarButtonItem: newBackButton];
	[newBackButton release];
    
    UIImage *masthead = [[KGOTheme sharedTheme] titleImageForNavBar];
    if (masthead) {
        self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:masthead] autorelease];
    } else {
        self.navigationItem.title = NSLocalizedString(@"Harvard", nil);
    }
    
    if (!_searchController) {
        _searchController = [[KGOSearchDisplayController alloc] initWithSearchBar:_searchBar delegate:self contentsController:self];
    }
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [_searchController release];
    _searchController = nil;
}

- (void)dealloc {
    [_preferences release];
    [_searchBar release];
    [_searchController release];
    [super dealloc];
}

#pragma mark Springboard helper methods

- (NSArray *)iconsForPrimaryModules:(BOOL)isPrimary {
    NSMutableArray *icons = [NSMutableArray array];
    NSArray *modules = (isPrimary) ? self.primaryModules : self.secondaryModules;
    
    KGOModule *aModule = [modules lastObject];
    CGSize labelSize = (isPrimary) ? [self moduleLabelMaxDimensions] : [self secondaryModuleLabelMaxDimensions];
    CGRect frame = CGRectZero;
    
    frame.size = [aModule iconImage].size;
    frame.size.width = fmax(frame.size.width, labelSize.width);
    frame.size.height += labelSize.height + (isPrimary) ? [self moduleLabelTitleMargin] : [self secondaryModuleLabelTitleMargin];
    
    for (aModule in modules) {
        SpringboardIcon *anIcon = [[[SpringboardIcon alloc] initWithFrame:frame] autorelease];
        [icons addObject:anIcon];
        
        anIcon.springboard = self;
        anIcon.module = aModule;
        
        // Add properties for accessibility/automation visibility.
        anIcon.isAccessibilityElement = YES;
        anIcon.accessibilityLabel = aModule.longName;
    }
    
    return icons;
}

#pragma mark KGOSearchDisplayDelegate

- (BOOL)searchControllerShouldShowSuggestions:(KGOSearchDisplayController *)controller {
    return YES;
}

- (NSArray *)searchControllerValidModules:(KGOSearchDisplayController *)controller {
    NSMutableArray *searchableModules = [NSMutableArray arrayWithCapacity:4];
    NSArray *modules = ((KGOAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
    for (KGOModule *aModule in modules) {
        if (aModule.supportsFederatedSearch) {
            [searchableModules addObject:aModule.tag];
        }
    }
    return searchableModules;
}

- (NSString *)searchControllerModuleTag:(KGOSearchDisplayController *)controller {
    return HomeTag;
}

- (void)searchController:(KGOSearchDisplayController *)controller didSelectResult:(id<KGOSearchResult>)aResult {
    // TODO: come up with a better way to figure out which module the search result belongs to
    BOOL didShow = NO;
    if ([aResult isKindOfClass:[PersonDetails class]]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:aResult, @"personDetails", nil];
        didShow = [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameDetail forModuleTag:PeopleTag params:params];
    }
    
    if (!didShow) {
        NSLog(@"home screen search controller failed to respond to search result %@", [aResult description]);
    }
}

#pragma mark config settings

- (CGSize)moduleLabelMaxDimensions {
    return [KGOHomeScreenViewController maxLabelDimensionsForModules:_primaryModules font:[self moduleLabelFont]];
}

- (CGSize)secondaryModuleLabelMaxDimensions {
    return [KGOHomeScreenViewController maxLabelDimensionsForModules:_secondaryModules font:[self secondaryModuleLabelFont]];
}

- (BOOL)showsSearchBar {
    NSNumber *number = [_preferences objectForKey:@"ShowsSearchBar"];
    return [number boolValue];
}

- (UIImage *)backgroundImage {
    NSString *filename = [_preferences objectForKey:@"BackgroundImage"];
    return [UIImage imageNamed:filename];
}

// primary modules

- (UIFont *)moduleLabelFont {
    NSDictionary *fontArgs = [_preferences objectForKey:@"ModuleLabelFont"];
    return [UIFont fontWithName:[fontArgs objectForKey:@"font"] size:[[fontArgs objectForKey:@"size"] floatValue]];
}

- (UIColor *)moduleLabelTextColor {
    NSDictionary *fontArgs = [_preferences objectForKey:@"ModuleLabelFont"];
    UIColor *color = [UIColor colorWithHexString:[fontArgs objectForKey:@"color"]];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (GridSpacing)moduleListSpacing {
    NSArray *args = [[_preferences objectForKey:@"ModuleListSpacing"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController spacingWithArgs:args];
}

- (GridPadding)moduleListMargins {
    NSArray *args = [[_preferences objectForKey:@"ModuleListMargins"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController paddingWithArgs:args];
}

- (CGFloat)moduleLabelTitleMargin {
    NSNumber *number = [_preferences objectForKey:@"ModuleLabelTitleMargin"];
    return [number floatValue];
}

// secondary modules

- (UIFont *)secondaryModuleLabelFont {
    NSDictionary *fontArgs = [_preferences objectForKey:@"SecondaryModuleLabelFont"];
    return [UIFont fontWithName:[fontArgs objectForKey:@"font"] size:[[fontArgs objectForKey:@"size"] floatValue]];
}

- (UIColor *)secondaryModuleLabelTextColor {
    NSDictionary *fontArgs = [_preferences objectForKey:@"SecondaryModuleLabelFont"];
    UIColor *color = [UIColor colorWithHexString:[fontArgs objectForKey:@"color"]];
    if (!color)
        color = [UIColor blackColor];
    return color;
}

- (GridSpacing)secondaryModuleListSpacing {
    NSArray *args = [[_preferences objectForKey:@"SecondaryModuleListSpacing"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController spacingWithArgs:args];
}

- (GridPadding)secondaryModuleListMargins {
    NSArray *args = [[_preferences objectForKey:@"SecondaryModuleListMargins"] componentsSeparatedByString:@" "];
    return [KGOHomeScreenViewController paddingWithArgs:args];
}

- (CGFloat)secondaryModuleLabelTitleMargin {
    NSNumber *number = [_preferences objectForKey:@"SecondaryModuleLabelTitleMargin"];
    return [number floatValue];
}

#pragma mark Private

- (void)loadModules {
    NSArray *modules = ((KGOAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
    NSMutableArray *primary = [NSMutableArray array];
    NSMutableArray *secondary = [NSMutableArray array];
    
    for (KGOModule *aModule in modules) {
        // special case for home module
        if ([aModule isKindOfClass:[HomeModule class]])
            continue;
        
        if (aModule.secondary) {
            [secondary addObject:aModule];
        } else {
            [primary addObject:aModule];
        }
    }
    
    [_secondaryModules release];
    _secondaryModules = [secondary copy];
    
    [_primaryModules release];
    _primaryModules = [primary copy];
}

+ (GridPadding)paddingWithArgs:(NSArray *)args {
    // top, left, bottom, right
    GridPadding padding;
    for (NSInteger i = 0; i < args.count; i++) {
        CGFloat value = [[args objectAtIndex:i] floatValue];
        switch (i) {
            case 0:
                padding.top = value;
                break;
            case 1:
                padding.left = value;
                break;
            case 2:
                padding.bottom = value;
                break;
            case 3:
                padding.right = value;
                break;
        }
    }
    return padding;
}

+ (GridSpacing)spacingWithArgs:(NSArray *)args {
    // width, height
    GridSpacing spacing;
    for (NSInteger i = 0; i < args.count; i++) {
        CGFloat value = [[args objectAtIndex:i] floatValue];
        switch (i) {
            case 0:
                spacing.width = value;
                break;
            case 1:
                spacing.height = value;
                break;
        }
    }
    return spacing;
}

+ (CGSize)maxLabelDimensionsForModules:(NSArray *)modules font:(UIFont *)font {
    CGFloat maxWidth = 0;
    CGFloat maxHeight = 0;
    for (KGOModule *aModule in modules) {
        NSArray *words = [aModule.longName componentsSeparatedByString:@" "];
        for (NSString *aWord in words) {
            CGSize size = [aWord sizeWithFont:font];
            if (size.width > maxWidth) {
                maxWidth = size.width;
            }
        }
        CGFloat height = [font lineHeight] * [words count];
        if (height > maxHeight) {
            height = maxHeight;
        }
    }
    return CGSizeMake(maxWidth, maxHeight);
}

@end
