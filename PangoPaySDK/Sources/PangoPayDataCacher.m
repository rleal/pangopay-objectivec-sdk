//
//  PangoPayDataCacher.m
//  PangoPaySDK
//
//  Created by Christian Bongardt on 24/12/13.
//  Copyright (c) 2013 Christian Bongardt. All rights reserved.
//

#import "PangoPayDataCacher.h"

@interface PangoPayDataCacher()

@property (strong,nonatomic) PNPUser *user;
@property (strong,nonatomic) UIImage *avatar;
@property (strong,nonatomic) NSMutableArray *notifications;
@property (strong,nonatomic) NSMutableArray *pangos;
@property (strong,nonatomic) NSMutableDictionary *pangoMovements;
@property (strong,nonatomic) NSDictionary *dataFileNames;
@property (strong,nonatomic) NSMutableArray *sentTransactions;
@property (strong,nonatomic) NSMutableArray *pendingTransactions;
@property (strong,nonatomic) NSMutableArray *receivedTransactions;
@property (strong,nonatomic) NSMutableArray *paymentRequests;
@property (strong,nonatomic) NSMutableArray  *countries;
@property (strong,nonatomic) NSMutableArray  *creditCards;
@property (strong,nonatomic) PNPUserValidation *validation;


@property dispatch_queue_t task;
@end

@implementation PangoPayDataCacher

+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

-(id) init{
    self = [super init];
    if (!self) return nil;
    self.dataFileNames = @{
                           @"user"                      : @"pnpuser",
                           @"avatar"                    : @"pnpuseravatar",
                           @"notifications"             : @"pnpnotifications",
                           @"pangos"                    : @"pnppangos",
                           @"pangoMovements"            : @"pnppangomovements",
                           @"sentTransactions"          : @"pnpsenttransactions",
                           @"receivedTransactions"      : @"pnpreceivedtransactions",
                           @"pendingTransactions"       : @"pnppendingtransactions",
                           @"paymentRequests"           : @"pnppaymentrequests",
                           @"countries"                 : @"pnpcountries",
                           @"validation"                : @"pnpuservalidation",
                           @"creditCards"               : @"pnpcreditcards",
                           };
    return self;
}

-(void) store{
    [self storeUser:self.user];
}


#pragma mark - User Methods
-(void) getUserDataWithSuccessCallback:(PnpUserDataSuccessHandler)successHandler
                      andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [self getUserDataWithSuccessCallback:successHandler
                        andErrorCallback:errorHandler
                      andRefreshCallback:nil];
    
}
-(void) getUserDataWithSuccessCallback:(PnpUserDataSuccessHandler) successHandler
                      andErrorCallback:(PnPGenericErrorHandler) errorHandler
                    andRefreshCallback:(PnpUserDataSuccessHandler) refreshHandler{
    [self getUser:^(PNPUser *user) {
        if(user != nil){
            if(successHandler) successHandler(user);
            if(refreshHandler){
                
                [super getUserDataWithSuccessCallback:^(PNPUser *user) {
                    [self storeUser:user];
                    refreshHandler(user);
                } andErrorCallback:errorHandler];
                
            }
        }else{
            
            [super getUserDataWithSuccessCallback:^(PNPUser *user) {
                [self storeUser:user];
                if(successHandler) successHandler(user);
            } andErrorCallback:errorHandler];
            
            
        }
    }];
}

-(void) getUserAvatarWithSuccessCallback:(PnpUserAvatarSuccessHandler)successHandler
                        andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [self getUserAvatarWithSuccessCallback:successHandler
                          andErrorCallback:errorHandler
                        andRefreshCallback:nil];
    
}

-(void) getUserAvatarWithSuccessCallback:(PnpUserAvatarSuccessHandler) successHandler
                        andErrorCallback:(PnPGenericErrorHandler) errorHandler
                      andRefreshCallback:(PnpUserAvatarSuccessHandler) refreshHandler{
    
    [self getUserAvatar:^(UIImage *avatar) {
        if(avatar != nil){
            if(successHandler) successHandler(avatar);
            if(refreshHandler){
                
                [super getUserAvatarWithSuccessCallback:^(UIImage *avatar) {
                    [self storeUserAvatar:avatar];
                    refreshHandler(avatar);
                } andErrorCallback:errorHandler];
                
            }
        }else{
            [super getUserAvatarWithSuccessCallback:^(UIImage *avatar) {
                [self storeUserAvatar:avatar];
                if(successHandler) successHandler(avatar);
            } andErrorCallback:errorHandler];
            
        }
    }];
}

-(void) getUserValidationStatusWithSuccessCallback:(PnpUserValidationSuccessHandler)successHandler
                                  andErrorCallback:(PnPGenericErrorHandler)errorHandler
                                andRefreshCallback:(PnpUserValidationSuccessHandler) refreshHandler{
    
    [self getUserValidationAndOnSuccess:^(PNPUserValidation *val) {
        if(val != nil){
            if(successHandler) successHandler(val);
            if(refreshHandler){
                [super getUserValidationStatusWithSuccessCallback:^(PNPUserValidation *val) {
                    [self storeUserValidation:val];
                    refreshHandler(val);
                } andErrorCallback:errorHandler];
            }
        }else{
            [super getUserValidationStatusWithSuccessCallback:^(PNPUserValidation *val) {
                [self storeUserValidation:val];
                if(successHandler)successHandler(val);
            } andErrorCallback:errorHandler];
            
        }
    }];
    
    
}

-(void) getUserValidationStatusWithSuccessCallback:(PnpUserValidationSuccessHandler)successHandler
                                  andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [self getUserValidationStatusWithSuccessCallback:successHandler
                                    andErrorCallback:errorHandler
                                  andRefreshCallback:nil];
}

-(void) uploadAvatar:(UIImage *)avatar
 withSuccessCallback:(PnPSuccessHandler)successHandler
    andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [super uploadAvatar:avatar
    withSuccessCallback:^{
        [self storeUserAvatar:avatar];
    }
       andErrorCallback:errorHandler];
}

-(void) uploadIdCard:(UIImage *)front
             andBack:(UIImage *)back
 withSuccessCallback:(PnPSuccessHandler)successHandler
    andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [super uploadIdCard:front
                andBack:back
    withSuccessCallback:^{
        [self getUserValidationStatusWithSuccessCallback:nil
                                        andErrorCallback:errorHandler
                                      andRefreshCallback:^(PNPUserValidation *val){
                                          successHandler();
                                      }];
    }
       andErrorCallback:errorHandler];
}


-(void) getUser:(PnpUserDataSuccessHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.user == nil){
            NSString *pnpUserPath = [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"user"]];
            self.user =[NSKeyedUnarchiver unarchiveObjectWithFile:pnpUserPath];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.user);} );
    });
}

-(void) storeUser:(PNPUser *) user{
    self.user = user;
    NSString *pnpUserPath = [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"user"]];
    [NSKeyedArchiver archiveRootObject:self.user toFile:pnpUserPath];
}

-(void) getUserAvatar:(PnpUserAvatarSuccessHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.avatar == nil){
            self.avatar = [UIImage imageWithData:[NSKeyedUnarchiver unarchiveObjectWithFile:
                                                  [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"avatar"]]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.avatar);} );
    });
    
}

-(void) storeUserAvatar:(UIImage *) avatar{
    self.avatar = avatar;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:UIImageJPEGRepresentation(avatar, 0)
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"avatar"]]];
    });
}

-(void) getUserValidationAndOnSuccess:(PnpUserValidationSuccessHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.validation == nil){
            self.validation = [NSKeyedUnarchiver unarchiveObjectWithFile:
                               [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"validation"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.validation);} );
    });
    
}

-(void) storeUserValidation:(PNPUserValidation *) validation{
    self.validation = validation;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.validation
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"validation"]]];
    });
}


#pragma mark - Credit cards

-(void) getCreditCardsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                         andErrorCallback:(PnPGenericErrorHandler) errorHandler
                          refreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    
    [self getCreditCardsOnSuccess:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getCreditCardsWithSuccessCallback:^(NSArray *data) {
                    [self storeCreditCards:data];
                    refreshHandler(data);
                } andErrorCallback:errorHandler];
            }
        }else{
            [super getCreditCardsWithSuccessCallback:^(NSArray *data) {
                [self storeCreditCards:data];
                if(successHandler)successHandler(data);
            } andErrorCallback:errorHandler];
        }
    }];
    
}

-(void) getCreditCardsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                         andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [self getCreditCardsWithSuccessCallback:successHandler
                           andErrorCallback:errorHandler
                            refreshCallback:nil];
    
}

-(void) deleteCard:(PNPCreditCard *)card
withSuccessCallback:(PnPSuccessHandler)successHandler
  andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [super deleteCard:card
  withSuccessCallback:^{
      [self getCreditCardsOnSuccess:^(NSArray *data) {
          NSMutableArray *cards = [NSMutableArray arrayWithArray:data];
          NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier == %@",card.identifier];
          NSMutableArray *filteredArray = [NSMutableArray arrayWithArray:[data filteredArrayUsingPredicate:p]];
          [cards removeObjectsInArray:filteredArray];
          [self storeCreditCards:cards];
          if(successHandler) successHandler();
      }];
  }
     andErrorCallback:errorHandler];
    
}

-(void) updateCard:(PNPCreditCard *)card
withSuccessCallback:(PnPSuccessHandler)successHandler
  andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [super updateCard:card
  withSuccessCallback:^{
      [self getCreditCardsOnSuccess:^(NSArray *data) {
          NSMutableArray *cards = [NSMutableArray arrayWithArray:data];
          NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier == %@",card.identifier];
          NSMutableArray *filteredArray = [NSMutableArray arrayWithArray:[data filteredArrayUsingPredicate:p]];
          [cards removeObjectsInArray:filteredArray];
          [cards addObject:card];
          [self storeCreditCards:cards];
          
          if(successHandler) successHandler();
      }];
  }
     andErrorCallback:errorHandler];
}

-(void) createCard:(PNPCreditCard *)card
withSuccessCallback:(PnPSuccessHandler)successHandler
  andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [super createCard:card withSuccessCallback:^{
        [self getCreditCardsWithSuccessCallback:nil
                               andErrorCallback:errorHandler
                                refreshCallback:^(NSArray *data) {
                                    if(successHandler) successHandler();
                                }];
    } andErrorCallback:errorHandler];
    
}


-(void) getCreditCardsOnSuccess:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.creditCards == nil){
            self.creditCards = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self pnpDataDirectoryPath]
                                                                           stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"creditCards"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.creditCards);} );
    });
    
    
}
-(void) storeCreditCards:(NSArray *) cards{
    self.creditCards = [NSMutableArray arrayWithArray:cards];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.creditCards
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"creditCards"]]];
    });
}

#pragma mark - Notification Methods
-(void) getNotificationsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                           andErrorCallback:(PnPGenericErrorHandler) errorHandler
                         andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    
    [self getNotifications:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getNotificationsWithSuccessCallback:^(NSArray *data) {
                    [self storeNotifications:data];
                    refreshHandler(data);
                } andErrorCallback:errorHandler];
                
            }
        }else{
            
            [super getNotificationsWithSuccessCallback:^(NSArray *data) {
                [self storeNotifications:data];
                if(successHandler)successHandler(data);
            } andErrorCallback:errorHandler];
            
        }
    }];
    
}

-(void) getNotificationsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                           andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [self getNotificationsWithSuccessCallback:successHandler
                             andErrorCallback:errorHandler
                           andRefreshCallback:nil];
    
}

-(void) deleteNotifications:(NSSet *) notifications
        withSuccessCallback:(PnPSuccessHandler)successHandler
           andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [super deleteNotifications:notifications
           withSuccessCallback:^{
               [self getNotificationsWithSuccessCallback:^(NSArray *data) {
                   NSMutableArray *a = [NSMutableArray arrayWithArray:data];
                   [a removeObjectsInArray:[notifications allObjects]];
                   [self storeNotifications:a];
                   if(successHandler)successHandler();
               } andErrorCallback:nil];
           }andErrorCallback:errorHandler];
    
}

-(void) deleteNotification:(PNPNotification *) notification
       withSuccessCallback:(PnPSuccessHandler)successHandler
          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [self deleteNotifications:[NSSet setWithObjects:notification, nil]
          withSuccessCallback:successHandler
             andErrorCallback:errorHandler];
}


-(void) getNotifications:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.notifications == nil){
            self.notifications = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self pnpDataDirectoryPath]
                                                                             stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"notifications"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.notifications);} );
    });
}

-(void) storeNotifications:(NSArray *) notifications{
    self.notifications = [NSMutableArray arrayWithArray:notifications];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.notifications
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"notifications"]]];
    });
}



#pragma mark - Pango Methods

-(void) getPangosWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                    andErrorCallback:(PnPGenericErrorHandler) errorHandler
                  andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    [self getPangos:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getPangosWithSuccessCallback:^(NSArray *data) {
                    [self storePangos:data];
                    refreshHandler(data);
                } andErrorCallback:errorHandler];
            }
        }else{
            [super getPangosWithSuccessCallback:^(NSArray *data) {
                [self storePangos:data];
                if(successHandler) successHandler(data);
            } andErrorCallback:errorHandler];
        }
    }];
}

-(void) getPangosWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                    andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [self getPangosWithSuccessCallback:successHandler
                      andErrorCallback:errorHandler
                    andRefreshCallback:nil];
    
}

-(void) getPangos:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.pangos == nil){
            self.pangos = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self pnpDataDirectoryPath]
                                                                      stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"pangos"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.pangos);} );
    });
    
}

-(void) storePangos:(NSArray *) pangos{
    
    self.pangos = [NSMutableArray arrayWithArray:pangos];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.pangos
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"pangos"]]];
    });
}


-(void) getPangoMovements:(PNPPango *) pango
      withSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
         andErrorCallback:(PnPGenericErrorHandler) errorHandler
       andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    
    [self getMovementsForPango:pango success:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getPangoMovements:pango withSuccessCallback:^(NSArray *data) {
                    [self storeMovements:data forPango:pango];
                    refreshHandler(data);
                } andErrorCallback:errorHandler];
            }
        }else{
            [super getPangoMovements:pango withSuccessCallback:^(NSArray *data) {
                [self storeMovements:data forPango:pango];
                if(successHandler) successHandler(data);
            } andErrorCallback:errorHandler];
        }
    }];
}

-(void) getPangoMovements:(PNPPango *)pango
      withSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
         andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [self getPangoMovements:pango
        withSuccessCallback:successHandler
           andErrorCallback:errorHandler andRefreshCallback:nil];
    
}

-(void) getMovementsForPango:(PNPPango *) pango
                     success:(PnPGenericNSAarraySucceddHandler) successHandler{
    if(pango == nil) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.pangoMovements == nil){
            self.pangoMovements = [NSKeyedUnarchiver unarchiveObjectWithFile:
                                   [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"pangoMovements"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler([self.pangoMovements objectForKey:pango.identifier]);} );
    });
}

-(void) storeMovements:(NSArray *) movements
              forPango:(PNPPango *) pango{
    if(self.pangoMovements == nil) self.pangoMovements = [NSMutableDictionary new];
    [self.pangoMovements setObject:[NSMutableArray arrayWithArray:movements] forKey:pango.identifier];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.pangoMovements
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"pangoMovements"]]];
    });
}


-(void) getPangoWithIdentifier:(NSNumber *) identifier
           withSuccessCallback:(PnpPangoDataSuccessHandler) successHandler
              andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [self getPangosWithSuccessCallback:^(NSArray *data) {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier = %@",identifier];
        NSArray *filteredPangos = [data filteredArrayUsingPredicate:p];
        if([filteredPangos count] == 0){
            successHandler(nil);
        }else{
            successHandler([filteredPangos objectAtIndex:0]);
        }
        
    } andErrorCallback:errorHandler];
    
}

-(void) updatePangoAlias:(PNPPango *) pango
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [super updatePangoAlias:pango
        withSuccessCallback:^{
            [self getPangosWithSuccessCallback:^(NSArray *data) {
                NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier = %@",pango.identifier];
                NSArray *filteredPangos = [data filteredArrayUsingPredicate:p];
                NSMutableArray *a = [NSMutableArray arrayWithArray:data];
                [a removeObjectsInArray:filteredPangos];
                [a addObject:pango];
                [self storePangos:a];
                if(successHandler)successHandler();
            } andErrorCallback:errorHandler];
        }andErrorCallback:errorHandler];
}

-(void) changeStatusForPango:(PNPPango *) pango
         withSuccessCallback:(PnPSuccessHandler)successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [super changeStatusForPango:pango
            withSuccessCallback:^{
                [self getPangosWithSuccessCallback:^(NSArray *data) {
                    NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier = %@",pango.identifier];
                    NSArray *filteredPangos = [data filteredArrayUsingPredicate:p];
                    NSMutableArray *a = [NSMutableArray arrayWithArray:data];
                    [a removeObjectsInArray:filteredPangos];
                    if([pango.status isEqualToString:PNPPangoStatusBlocked]){
                        pango.status = PNPPangoStatusUnblocked;
                    }else{
                        pango.status = PNPPangoStatusBlocked;
                    }
                    [a addObject:pango];
                    [self storePangos:a];
                    if(successHandler)successHandler();
                } andErrorCallback:errorHandler];
            }
               andErrorCallback:errorHandler];
}

-(void) cancelPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [super cancelPango:pango
   withSuccessCallback:^{
       [self getPangosWithSuccessCallback:^(NSArray *data) {
           NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier = %@",pango.identifier];
           NSArray *filteredPangos = [data filteredArrayUsingPredicate:p];
           NSMutableArray *a = [NSMutableArray arrayWithArray:data];
           [a removeObjectsInArray:filteredPangos];
           [self storePangos:a];
           if(successHandler)successHandler();
       } andErrorCallback:errorHandler];
       
   }
      andErrorCallback:errorHandler];
    
}


-(void) unlinkPango:(PNPPango *) pango
withSuccessCallback:(PnPSuccessHandler)successHandler
   andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [super unlinkPango:pango
   withSuccessCallback:^{
       [self getPangosWithSuccessCallback:^(NSArray *data) {
           NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier = %@",pango.identifier];
           NSArray *filteredPangos = [data filteredArrayUsingPredicate:p];
           NSMutableArray *a = [NSMutableArray arrayWithArray:data];
           [a removeObjectsInArray:filteredPangos];
           [self storePangos:a];
           if(successHandler)successHandler();
       } andErrorCallback:errorHandler];
       
   }
      andErrorCallback:errorHandler];
    
}

-(void) rechargePango:(PNPPango *) pango
           withAmount:(NSNumber *) amount
  withSuccessCallback:(PnPSuccessHandler) successHandler
     andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [super rechargePango:pango
              withAmount:amount
     withSuccessCallback:^{
         [self getPangosWithSuccessCallback:nil
                           andErrorCallback:errorHandler
                         andRefreshCallback:^(NSArray *data) {
                             [self storePangos:data];
                             if(successHandler) successHandler();
                         }];
     }
        andErrorCallback:errorHandler];
    
}

-(void) extractFromPango:(PNPPango *) pango
                  amount:(NSNumber *) amount
     withSuccessCallback:(PnPSuccessHandler) successHandler
        andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [super extractFromPango:pango
                     amount:amount
        withSuccessCallback:^{
            [self getPangosWithSuccessCallback:nil
                              andErrorCallback:errorHandler
                            andRefreshCallback:^(NSArray *data) {
                                [self storePangos:data];
                                if(successHandler) successHandler();
                            }];
        }
           andErrorCallback:errorHandler];
    
}





#pragma mark - Send transaction methods


-(void) sendTransactionWithAmount:(NSNumber *) amount
                         toPrefix:(NSString *) prefix
                            phone:(NSString *) phone
                              pin:(NSString *) pin
              withSuccessCallback:(PnPSuccessHandler) successHandler
                 andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [super sendTransactionWithAmount:amount
                            toPrefix:prefix
                               phone:phone
                                 pin:pin
                 withSuccessCallback:^{
                     [self getUserDataWithSuccessCallback:nil andErrorCallback:errorHandler andRefreshCallback:^(PNPUser *user) {
                         successHandler();
                     }];
                 }
                    andErrorCallback:errorHandler];
    
}


#pragma mark - Transaction methods


-(void) getTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                          andErrorCallback:(PnPGenericErrorHandler) errorHandler
                        andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    __block int counter = 0;
    __block int refreshCounter = 0;
    NSMutableArray *transactionArray = [NSMutableArray new];
    NSMutableArray *refreshTransactionArray = [NSMutableArray new];
    __block BOOL calledBack = NO;
    
    
    void (^refreshCallback)(NSArray * );
    
    if(refreshHandler){
        refreshCallback  = ^(NSArray *data){
            [refreshTransactionArray addObjectsFromArray:data];
            refreshCounter += 1;
            if(refreshCounter == 3){
                refreshHandler(refreshTransactionArray);
            }
        };
    }else{
        refreshCallback = nil;
    }
    
    [self getSentTransactionsWithSuccessCallback:^(NSArray *data) {
        [transactionArray addObjectsFromArray:data];
        counter+= 1;
        if(counter == 3){
            if(successHandler) successHandler(transactionArray);
        }
    } andErrorCallback:^(NSError *error) {
        if(errorHandler && !calledBack) {
            errorHandler(error);
            calledBack = YES;
        }
    } andRefreshCallback:refreshCallback];
    
    [self getReceivedTransactionsWithSuccessCallback:^(NSArray *data) {
        [transactionArray addObjectsFromArray:data];
        counter+= 1;
        if(counter == 3){
            if(successHandler) successHandler(transactionArray);
        }
    } andErrorCallback:^(NSError *error) {
        if(errorHandler && !calledBack) {
            errorHandler(error);
            calledBack = YES;
        }
    }andRefreshCallback:refreshCallback];
    
    [self getPendingTransactionsWithSuccessCallback:^(NSArray *data) {
        [transactionArray addObjectsFromArray:data];
        counter+= 1;
        if(counter == 3){
            if(successHandler) successHandler(transactionArray);
        }
    } andErrorCallback:^(NSError *error) {
        if(errorHandler && !calledBack) {
            errorHandler(error);
            calledBack = YES;
        }
    }andRefreshCallback:refreshCallback];
}

-(void) getReceivedTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                  andErrorCallback:(PnPGenericErrorHandler) errorHandler
                                andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    [self getReceivedTransactionsOnSuccess:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                
                [super getReceivedTransactionsWithSuccessCallback:^(NSArray *data) {
                    [self storeReceivedTransactions:data];
                    refreshHandler(data);
                } andErrorCallback:errorHandler];
                
            }
        }else{
            [super getReceivedTransactionsWithSuccessCallback:^(NSArray *data) {
                [self storeReceivedTransactions:data];;
                if(successHandler) successHandler(data);
            } andErrorCallback:errorHandler];
        }
    }];
    
}

-(void) getSentTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                              andErrorCallback:(PnPGenericErrorHandler) errorHandler
                            andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    [self getSentTransactionsOnSuccess:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getSentTransactionsWithSuccessCallback:^(NSArray *data) {
                    [self storeSentTransactions:data];
                    refreshHandler(data);
                } andErrorCallback:errorHandler];
                
            }
        }else{
            [super getSentTransactionsWithSuccessCallback:^(NSArray *data) {
                [self storeSentTransactions:data];
                if(successHandler) successHandler(data);
            } andErrorCallback:errorHandler];
        }
    }];
    
}


-(void) getPendingTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                 andErrorCallback:(PnPGenericErrorHandler) errorHandler
                               andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    
    [self getPendingTransactionsOnSuccess:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getPendingTransactionsWithSuccessCallback:^(NSArray *data) {
                    [self storePendingTransactions:data];
                    refreshHandler(data);
                } andErrorCallback:errorHandler];
            }
        }else{
            [super getPendingTransactionsWithSuccessCallback:^(NSArray *data) {
                [self storePendingTransactions:data];
                if(successHandler) successHandler(data);
            } andErrorCallback:errorHandler];
        }
        
    }];
    
}

-(void) cancelPendingTransaction:(PNPTransactionPending *)transaction
             withSuccessCallback:(PnPSuccessHandler)successHandler
                andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    
    [super cancelPendingTransaction:transaction
                withSuccessCallback:^{
                    [self getPendingTransactionsWithSuccessCallback:^(NSArray *data) {
                        NSMutableArray *a = [NSMutableArray arrayWithArray:data];
                        [a removeObject:transaction];
                        [self storePendingTransactions:a];
                        
                        [self getUserDataWithSuccessCallback:nil
                                            andErrorCallback:errorHandler
                                          andRefreshCallback:^(PNPUser *user) {
                                              if(successHandler) successHandler();
                                          }];
                    }
                                                   andErrorCallback:errorHandler
                                                 andRefreshCallback:nil];
                }
                   andErrorCallback:errorHandler];
    
}


-(void) getTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                          andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [self getTransactionsWithSuccessCallback:successHandler
                            andErrorCallback:errorHandler
                          andRefreshCallback:nil];
    
}

-(void) getReceivedTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                  andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [self getReceivedTransactionsWithSuccessCallback:successHandler
                                    andErrorCallback:errorHandler
                                  andRefreshCallback:nil];
    
}

-(void) getSentTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                              andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [self getSentTransactionsWithSuccessCallback:successHandler
                                andErrorCallback:errorHandler
                              andRefreshCallback:nil];
    
}

-(void) getPendingTransactionsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                                 andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    [self getPendingTransactionsWithSuccessCallback:successHandler
                                   andErrorCallback:errorHandler
                                 andRefreshCallback:nil];
    
}

-(void) getPendingTransactionsOnSuccess:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.pendingTransactions == nil){
            self.pendingTransactions = [NSKeyedUnarchiver unarchiveObjectWithFile:
                                        [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"pendingTransactions"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.pendingTransactions);} );
    });
}

-(void) storePendingTransactions:(NSArray *) transactions{
    self.pendingTransactions = [NSMutableArray arrayWithArray:transactions];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.pendingTransactions
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"pendingTransactions"]]];
    });
}


-(void) getSentTransactionsOnSuccess:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.sentTransactions == nil){
            self.sentTransactions = [NSKeyedUnarchiver unarchiveObjectWithFile:
                                     [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"sentTransactions"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.sentTransactions);} );
    });
}

-(void) storeSentTransactions:(NSArray *) transactions{
    self.sentTransactions = [NSMutableArray arrayWithArray:transactions];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.sentTransactions
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"sentTransactions"]]];
    });
}


-(void) getReceivedTransactionsOnSuccess:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.receivedTransactions == nil){
            self.receivedTransactions = [NSKeyedUnarchiver unarchiveObjectWithFile:
                                         [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"receivedTransactions"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.receivedTransactions);} );
    });
}

-(void) storeReceivedTransactions:(NSArray *) transactions{
    self.receivedTransactions = [NSMutableArray arrayWithArray:transactions];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.receivedTransactions
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"receivedTransactions"]]];
    });
}


#pragma mark - Payment requests

-(void) getPaymentRequestsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                             andErrorCallback:(PnPGenericErrorHandler)errorHandler
                           andRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    
    [self getPaymentRequestsOnSuccess:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
                    [self storePaymentRequests:data];
                    refreshHandler(data);
                } andErrorCallback:nil];
            }
        }else{
            [super getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
                [self storePaymentRequests:data];
                if(successHandler) successHandler(data);
            } andErrorCallback:nil];
        }
    }];
    
}

-(void) getPaymentRequestsWitId:(NSNumber *)identifier
             andSuccessCallback:(PnPPaymentRequestSuccessHandler) successHandler
               andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [self getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"self.identifier == %@",identifier];
        NSArray *f = [data filteredArrayUsingPredicate:p];
        if([f count] > 0){
            if(successHandler) successHandler([f objectAtIndex:0]);
        }else{
            if(successHandler) successHandler(nil);
        }
    } andErrorCallback:errorHandler];
    
}



-(void) getPaymentRequestsWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [self getPaymentRequestsWithSuccessCallback:successHandler
                               andErrorCallback:errorHandler
                             andRefreshCallback:nil];
    
}

-(void) cancelPaymentRequest:(PNPPaymentRequest *) request
         withSuccessCallback:(PnPSuccessHandler) successHandler
            andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [super cancelPaymentRequest:request
            withSuccessCallback:^{
                [self getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
                    NSMutableArray *a = [NSMutableArray arrayWithArray:data];
                    [a removeObject:request];
                    [self storePaymentRequests:a];
                    if(successHandler) successHandler();
                } andErrorCallback:errorHandler];
            }
               andErrorCallback:errorHandler];
    
}

-(void) confirmPaymentRequest:(PNPPaymentRequest *) request
                          pin:(NSString *) pin
          withSuccessCallback:(PnPSuccessHandler) successHandler
             andErrorCallback:(PnPGenericErrorHandler) errorHandler{
    
    [super confirmPaymentRequest:request
                             pin:pin
             withSuccessCallback:^{
                 [self getPaymentRequestsWithSuccessCallback:^(NSArray *data) {
                     NSMutableArray *a = [NSMutableArray arrayWithArray:data];
                     [a removeObject:request];
                     [self storePaymentRequests:a];
                     [self getUserDataWithSuccessCallback:nil
                                         andErrorCallback:errorHandler
                                       andRefreshCallback:^(PNPUser *user) {
                                           if(successHandler) successHandler();
                                       }];
                 } andErrorCallback:errorHandler];
             }
                andErrorCallback:errorHandler];
    
}


-(void) getPaymentRequestsOnSuccess:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.paymentRequests == nil){
            self.paymentRequests = [NSKeyedUnarchiver unarchiveObjectWithFile:
                                    [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"paymentRequests"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.paymentRequests);} );
    });
}

-(void) storePaymentRequests:(NSArray *) requests{
    self.paymentRequests = [NSMutableArray arrayWithArray:requests];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.paymentRequests
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"paymentRequests"]]];
    });
}



#pragma mark - Static data

-(void) getCountriesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler) successHandler
                       andErrorCallback:(PnPGenericErrorHandler) errorHandler
                    withRefreshCallback:(PnPGenericNSAarraySucceddHandler) refreshHandler{
    
    [self getCountriesOnSuccess:^(NSArray *data) {
        if(data != nil){
            if(successHandler) successHandler(data);
            if(refreshHandler){
                [super getCountriesWithSuccessCallback:^(NSArray *data) {
                    [self storeCountries:data];
                    refreshHandler(data);
                } andErrorCallback:nil];
            }
        }else{
            [super getCountriesWithSuccessCallback:^(NSArray *data) {
                [self storeCountries:data];
                if(successHandler) successHandler(data);
            } andErrorCallback:nil];
        }
    }];
    
    
    
    
}

-(void) getCountriesWithSuccessCallback:(PnPGenericNSAarraySucceddHandler)successHandler
                       andErrorCallback:(PnPGenericErrorHandler)errorHandler{
    [self getCountriesWithSuccessCallback:successHandler
                         andErrorCallback:errorHandler
                      withRefreshCallback:nil];
    
}


-(void) storeCountries:(NSArray *) countries{
    self.countries = [NSMutableArray arrayWithArray:countries];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NSKeyedArchiver archiveRootObject:self.countries
                                    toFile:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"countries"]]];
    });
    
}

-(void) getCountriesOnSuccess:(PnPGenericNSAarraySucceddHandler) successHandler{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if(self.countries == nil){
            self.countries = [NSKeyedUnarchiver unarchiveObjectWithFile:
                              [[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:@"countries"]]];
        }
        if(successHandler) dispatch_sync(dispatch_get_main_queue(), ^{ successHandler(self.countries);} );
    });
}

#pragma mark - Logout methods

-(void) logout{
    [super logout];
    self.user = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self deletePnpData];
    });
}

- (NSString *) pnpDataDirectoryPath
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return docsPath;
    
}

-(void) deletePnpData{
    for (id key in self.dataFileNames){
        [[NSFileManager defaultManager] removeItemAtPath:[[self pnpDataDirectoryPath] stringByAppendingPathComponent:[self.dataFileNames objectForKey:key]] error:nil];
    }
}

@end
