// Copyright (c) 2015-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RCTConvert+FBSDKSharingContent.h"

@implementation RCTConvert(FBSDKSharingContent)

#pragma mark - Class Methods

+ (RCTFBSDKSharingContent)RCTFBSDKSharingContent:(id)json
{
  NSDictionary *contentData = [self NSDictionary:json];
  if (contentData) {
    id<FBSDKSharingContent> content = nil;
    // Build the right kind of content based on the specified content type
    NSString *contentType = [self NSString:contentData[@"contentType"]];
    if ([contentType isEqualToString:@"link"]) {
      content = RCTBuildLinkContent(contentData);
    } else if ([contentType isEqualToString:@"photo"]) {
      content = RCTBuildPhotoContent(contentData);
    } else if ([contentType isEqualToString:@"video"]) {
      content = RCTBuildVideoContent(contentData);
    } else if ([contentType isEqualToString:@"open-graph"]) {
      content = RCTBuildOpenGraphContent(contentData);
    } else {
      return nil;
    }
    if (content) {
      RCTAppendGenericContent(content, contentData);
    }
    return content;
  } else {
    return nil;
  }
}

+ (FBSDKShareOpenGraphObject *)FBSDKShareOpenGraphObject:(id)json
{
  NSDictionary *contentData = [self NSDictionary:json];
  if (contentData) {
    return RCTBuildOpenGraphObject(contentData[@"_properties"]);
  }
  return nil;
}

#pragma mark - Helper Methods

static void RCTAppendGenericContent(RCTFBSDKSharingContent contentObject, NSDictionary *contentData)
{
  contentObject.contentURL = [RCTConvert NSURL:contentData[@"contentURL"]];
  contentObject.peopleIDs = [RCTConvert NSStringArray:contentData[@"peopleIDs"]];
  contentObject.placeID = [RCTConvert NSString:contentData[@"placeID"]];
  contentObject.ref = [RCTConvert NSString:contentData[@"ref"]];
}

static FBSDKShareLinkContent *RCTBuildLinkContent(NSDictionary *contentData)
{
  FBSDKShareLinkContent *linkContent = [[FBSDKShareLinkContent alloc] init];
  linkContent.contentDescription = [RCTConvert NSString:contentData[@"contentDescription"]];
  linkContent.contentTitle = [RCTConvert NSString:contentData[@"contentTitle"]];
  linkContent.imageURL = [RCTConvert NSURL:contentData[@"imageURL"]];
  return linkContent;
}

static FBSDKSharePhotoContent *RCTBuildPhotoContent(NSDictionary *contentData)
{
  NSArray *photoData = [RCTConvert NSArray:contentData[@"photos"]];
  FBSDKSharePhotoContent *photoContent = [[FBSDKSharePhotoContent alloc] init];
  NSMutableArray *photos = [[NSMutableArray alloc] init];
  // Generate an FBSDKSharePhoto for each item in photoData
  for (NSDictionary *p in photoData) {
    FBSDKSharePhoto *photo = RCTBuildPhoto(p);
    if (photo.image) {
      [photos addObject:photo];
    }
  }
  photoContent.photos = photos;
  return photoContent;
}

static FBSDKSharePhoto *RCTBuildPhoto(NSDictionary *photoData)
{
  UIImage *image = [RCTConvert UIImage:photoData[@"imageURL"]];
  BOOL userGenerated = [RCTConvert BOOL:photoData[@"userGenerated"]];
  FBSDKSharePhoto *photo = [FBSDKSharePhoto photoWithImage:image userGenerated:userGenerated];
  photo.caption = [RCTConvert NSString:photoData[@"caption"]];
  return photo;
}

static FBSDKShareVideoContent *RCTBuildVideoContent(NSDictionary *contentData)
{
  FBSDKShareVideoContent *videoContent = [[FBSDKShareVideoContent alloc] init];
  NSDictionary *videoData = [RCTConvert NSDictionary:contentData[@"video"]];
  NSURL *videoURL = [RCTConvert NSURL:videoData[@"videoURL"]];
  FBSDKShareVideo *video = [FBSDKShareVideo videoWithVideoURL:videoURL];
  videoContent.video = video;
  if (contentData[@"previewPhoto"]) {
    FBSDKSharePhoto *previewPhoto = RCTBuildPhoto([RCTConvert NSDictionary:contentData[@"previewPhoto"]]);
    videoContent.previewPhoto = previewPhoto;
  }
  return videoContent;
}

static FBSDKShareOpenGraphContent *RCTBuildOpenGraphContent(NSDictionary *contentData)
{
  FBSDKShareOpenGraphContent *openGraphContent = [[FBSDKShareOpenGraphContent alloc] init];
  openGraphContent.previewPropertyName = [RCTConvert NSString:contentData[@"previewPropertyName"]];
  openGraphContent.action = RCTBuildOpenGraphAction([RCTConvert NSDictionary:contentData[@"action"]]);
  return openGraphContent;
}

static FBSDKShareOpenGraphAction *RCTBuildOpenGraphAction(NSDictionary *actionData)
{
  FBSDKShareOpenGraphAction *action = nil;
  if (actionData) {
    action = [[FBSDKShareOpenGraphAction alloc] init];
    NSDictionary *properties = [RCTConvert NSDictionary:actionData[@"_properties"]];
    for (NSString *key in properties.allKeys) {
      NSDictionary *element = [RCTConvert NSDictionary:properties[key]];
      RCTAddElementToOpenGraph(key, element, action);
    }
    action.actionType = [RCTConvert NSString:actionData[@"actionType"]];
  }
  return action;
}

static void RCTAddElementToOpenGraph(NSString *key, NSDictionary *element, FBSDKShareOpenGraphValueContainer *container)
{
  NSString *type = [RCTConvert NSString:element[@"type"]];
  if ([type isEqualToString:@"number"]) {
    [container setNumber:[RCTConvert NSNumber:element[@"value"]] forKey:key];
  } else if ([type isEqualToString:@"string"]) {
    [container setString:[RCTConvert NSString:element[@"value"]] forKey:key];
  } else if ([type isEqualToString:@"url"]) {
    [container setURL:[RCTConvert NSURL:element[@"value"]] forKey:key];
  } else if ([type isEqualToString:@"photo"]) {
    [container setPhoto:RCTBuildPhoto(element[@"value"]) forKey:key];
  } else if ([type isEqualToString:@"open-graph-object"]) {
    NSDictionary *properties = [RCTConvert NSDictionary:([RCTConvert NSDictionary:element[@"value"]])[@"_properties"]];
    [container setObject:RCTBuildOpenGraphObject(properties) forKey:key];
  } else if ([type isEqualToString:@"array"]) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSDictionary *e in [RCTConvert NSArray:element[@"value"]]) {
      RCTAddOpenGraphElementToArray(e, array);
    }
    [container setArray:array forKey:key];
  }
}

static FBSDKShareOpenGraphObject *RCTBuildOpenGraphObject(NSDictionary *objectData)
{
  FBSDKShareOpenGraphObject *object = [[FBSDKShareOpenGraphObject alloc] init];
  for (NSString *k in objectData.allKeys) {
    NSDictionary *element = [RCTConvert NSDictionary:objectData[k]];
    RCTAddElementToOpenGraph(k, element, object);
  }
  return object;
}

static void RCTAddOpenGraphElementToArray(NSDictionary *element, NSMutableArray *array)
{
  NSString *type = [RCTConvert NSString:element[@"type"]];
  if ([type isEqualToString:@"number"]) {
    [array addObject:[RCTConvert NSNumber:element[@"value"]]];
  } else if ([type isEqualToString:@"string"]) {
    [array addObject:[RCTConvert NSString:element[@"value"]]];
  } else if ([type isEqualToString:@"url"]) {
    [array addObject:[RCTConvert NSURL:element[@"value"]]];
  } else if ([type isEqualToString:@"photo"]) {
    [array addObject:RCTBuildPhoto(element[@"value"])];
  } else if ([type isEqualToString:@"open-graph-object"]) {
    NSDictionary *properties = [RCTConvert NSDictionary:([RCTConvert NSDictionary:element[@"value"]])[@"_properties"]];
    [array addObject:RCTBuildOpenGraphObject(properties)];
  }
}

@end