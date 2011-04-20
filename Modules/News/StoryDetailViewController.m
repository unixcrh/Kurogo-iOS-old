#import "StoryDetailViewController.h"
#import "KGOAppDelegate.h"
#import "UIKit+KGOAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOHTMLTemplate.h"
#import "StoryListViewController.h"
#import "StoryGalleryViewController.h"
#import "NewsImage.h"
#import "KGOShareButtonController.h"

@interface StoryDetailViewController (Private) 

- (void)displayCurrentStory;

@end

@implementation StoryDetailViewController

@synthesize newsController, story, stories, storyView, multiplePages;

- (void)loadView {
    [super loadView]; // surprisingly necessary empty call to super due to the way memory warnings work
	
	shareController = [[KGOShareButtonController alloc] initWithContentsController:self];
    shareController.shareTypes = KGOShareControllerShareTypeEmail | KGOShareControllerShareTypeFacebook | KGOShareControllerShareTypeTwitter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	storyView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    storyView.dataDetectorTypes = UIDataDetectorTypeLink;
    storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyView.scalesPageToFit = NO;
	[self.view addSubview: storyView];
	storyView.delegate = self;
    
    if(multiplePages) {
        storyPager = [[KGODetailPager alloc] initWithPagerController:self delegate:self];
        
        UIBarButtonItem * segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView: storyPager];
        self.navigationItem.rightBarButtonItem = segmentBarItem;
        [segmentBarItem release];
        
        [storyPager selectPageAtSection:initialIndexPath.section row:initialIndexPath.row];
    } else {
        [self displayCurrentStory];
    }
}

- (void) setInitialIndexPath:(NSIndexPath *)theInitialIndexPath  {
    initialIndexPath = [theInitialIndexPath retain];
}

# pragma KGODetailPagerController methods
- (NSInteger)numberOfSections:(KGODetailPager *)pager {
    return 1;
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section {
    return self.stories.count;
}

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath {
    return [self.stories objectAtIndex:indexPath.row];
}

# pragma 
- (void)pager:(KGODetailPager*)pager showContentForPage:(id<KGOSearchResult>)content {
    if(self.story == content) {
        // story already being shown
        return;
    }
    
    self.story = (NewsStory *)content;
    [self displayCurrentStory];
}

- (void)displayCurrentStory {

    KGOHTMLTemplate *template = [KGOHTMLTemplate templateWithPathName:@"modules/news/news_story_template.html"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, y"];
    NSString *postDate = [dateFormatter stringFromDate:story.postDate];
	[dateFormatter release];
    
    NSString *thumbnailURL = story.thumbImage.url;
    
    if (!thumbnailURL) {
        thumbnailURL = @"";
    }
    
	NSString *isBookmarked = ([self.story.bookmarked boolValue]) ? @"on" : @"";
	
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    [values setValue:story.title forKey:@"TITLE"];
    [values setValue:story.author forKey:@"AUTHOR"];
    [values setValue:isBookmarked forKey:@"BOOKMARKED"];
    [values setValue:postDate forKey:@"DATE"];
    [values setValue:thumbnailURL forKey:@"THUMBNAIL_URL"];
    [values setValue:story.body forKey:@"BODY"];
    [values setValue:story.summary forKey:@"DEK"];
    
    // mark story as read
    self.story.read = [NSNumber numberWithBool:YES];
	[[CoreDataManager sharedManager] saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [storyView loadTemplate:template values:values];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	BOOL result = YES;

	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		NSURL *url = [request URL];
        NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];

		if ([[url path] rangeOfString:[baseURL path] options:NSAnchoredSearch].location == NSNotFound) {
            [[UIApplication sharedApplication] openURL:url];
            result = NO;
        } else {
            if ([[url path] rangeOfString:@"bookmark" options:NSBackwardsSearch].location != NSNotFound) {
				// toggle bookmarked state
                BOOL newBookmarkState = [self.story.bookmarked boolValue] ? NO : YES;
                [[NewsDataManager sharedManager] story:self.story bookmarked:newBookmarkState];
			} else if ([[url path] rangeOfString:@"share" options:NSBackwardsSearch].location != NSNotFound) {
                shareController.actionSheetTitle = @"Share article with a friend";
                shareController.shareTitle = story.title;
                shareController.shareBody = story.body;
                shareController.shareURL = story.link;
				[shareController shareInView:self.view];
			}
            result = NO;
		}
	}
	return result;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	[shareController release];
	shareController = nil;
}

- (void)dealloc {
    [shareController release];
	[storyView release];
    self.story = nil;
    self.stories = nil;
    [initialIndexPath release];
    [super dealloc];
}

@end
