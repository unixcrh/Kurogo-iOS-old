#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "JSONAPIRequest.h"
#import "PolygonOverlay.h"


@interface ArcGISMapSearchResultAnnotation : NSObject <MKAnnotation> {

	CLLocationCoordinate2D _coordinate;
    NSString *_uniqueID; // hidden
	NSString *_name;
	NSString *_street;
	NSString *_city;
    NSInteger yearBuilt;

    PolygonOverlay *_polygon;
    
	// has the data of this object been populated yet
	BOOL _dataPopulated;
	
	NSDictionary* _info;
	
	// flag indicating if this instance was loaded from a bookmark
	BOOL _bookmark;
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) PolygonOverlay *polygon;

@property (nonatomic, retain) NSString *uniqueID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *street;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, assign) NSInteger yearBuilt;
@property (nonatomic, retain) NSDictionary *info;

@property BOOL dataPopulated;
@property BOOL bookmark;

+ (void)executeServerSearchWithQuery:(NSString *)query jsonDelegate:(id<JSONAPIDelegate>)delegate object:(id)object;

- (id)initWithInfo:(NSDictionary*)info;
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (BOOL)canAddOverlay;

@end





// the mapsearch for courses outputs this kind of data:

/*
 "feature_type" : "Course Location",
 "search_string" : "barker center 114 kresge room",
 "match_string" : "Barker Center 114 Kresge Room",
 "xcoord" : "760329.91",
 "ycoord" : "2961044.576"
 */

// TODO: decide whether we need a separate annotation class for this


/*

@interface HarvardMapSearchResultAnnotation : NSObject <MKAnnotation> {
    NSString *_featureType;
    NSString *_searchString;
    NSString *_matchString;
    CLLocationCoordinate2D _coordinate;
}

@property (nonatomic, retain) NSString *featureType;
@property (nonatomic, retain) NSString *matchString;
@property (nonatomic, retain) NSString *searchString;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end

*/