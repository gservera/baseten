//
// BXSynchronizedArrayController.m
// BaseTen
//
// Copyright 2008-2010 Marko Karppinen & Co. LLC.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <BaseTen/BaseTen.h>
#import <BaseTen/BXEnumerate.h>
#import "BXDatabaseContextPrivateARC.h"
#import <BaseTen/BXContainerProxy.h>
#import <BaseTen/BXSetRelationProxy.h>
#import <BaseTen/BXRelationshipDescriptionPrivate.h>
#import <BaseTen/BXForeignKey.h>
#import <BaseTen/BXLogger.h>
#import <BaseTen/BXHOM.h>
#import "BXSynchronizedArrayController.h"
#import "NSController+BXAppKitAdditions.h"
#import "BXObjectStatusToColorTransformer.h"
#import "BXObjectStatusToEditableTransformer.h"


//FIXME: Handle locks


@interface BXSynchronizedArrayController ()
- (void) _endConnecting: (NSNotification *) notification;

/** Key for binding to a to-many rel */
@property (nonatomic, copy) NSString * contentBindingKey;
@end

@implementation NSObject (BXSynchronizedArrayControllerAdditions)
- (BOOL)BXIsRelationshipProxy {
	return NO;
}
@end


@implementation NSProxy (BXSynchronizedArrayControllerAdditions)
- (BOOL)BXIsRelationshipProxy {
	return NO;
}
@end


@implementation BXSetRelationProxy (BXSynchronizedArrayControllerAdditions)
- (BOOL)BXIsRelationshipProxy {
	return YES;
}
@end


/**
 * \brief An NSArrayController subclass for use with BaseTen.
 *
 * A BXSynchronizedArrayController updates its contents automatically based on notifications received 
 * from a database context. In order to function, its databaseContext outlet needs to be connected. 
 * It may also fetch objects when the context connects. However, this option should not be enabled 
 * if the controller's contents are bound to a relationship in a database object.
 * \ingroup baseten_appkit
 */
@implementation BXSynchronizedArrayController

+ (void)initialize {
    if (self == [BXSynchronizedArrayController class]) {
        // Register the transformers with the names that we refer to them with
        id transformer = [[BXObjectStatusToColorTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer
                                        forName:NSStringFromClass([transformer class])];
        transformer = [[BXObjectStatusToEditableTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer
                                        forName:NSStringFromClass([transformer class])];
        [self exposeBinding:NSStringFromSelector(@selector(databaseContext))];
        [self exposeBinding:NSStringFromSelector(@selector(modalWindow))];
        [self exposeBinding:NSStringFromSelector(@selector(selectedObjects))];
        [BXDatabaseContext loadedAppKitFramework];
    }
}

- (instancetype)initWithContent:(id)content {
    self = [super initWithContent:content];
    if (self) {
        self.automaticallyPreparesContent = NO;
        self.editable = NO;
        self.fetchesAutomatically = NO;
        mChanging = NO;
		mShouldAddToContent = YES;
		self.locksRowsOnBeginEditing = YES;
    }
    return self;
}

- (void)awakeFromNib {
    BXDatabaseContext *ctx = _databaseContext;
    _databaseContext = nil;
    self.databaseContext = ctx;
	NSWindow* aWindow = [self BXWindow];
	[_databaseContext setUndoManager: [aWindow undoManager]];
    [super awakeFromNib];
}

- (BXDatabaseContext *)BXDatabaseContext {
    return _databaseContext;
}

- (NSWindow *)BXWindow {
    return modalWindow;
}

- (void) prepareEntity
{
	BXAssertVoidReturn (_databaseContext, @"Expected databaseContext not to be nil. Was it set or bound in Interface Builder?");
	
	[self setEntityDescription: nil];
	BXDatabaseObjectModel *objectModel = [_databaseContext databaseObjectModel];
	BXEntityDescription* entityDescription = [objectModel entityForTable: [self tableName] inSchema: [self schemaName]];

	if (entityDescription)
	{
		[entityDescription setDatabaseObjectClass: NSClassFromString ([self databaseObjectClassName])];                
		[self setEntityDescription: entityDescription];
	}
	else
	{
		[self BXHandleError: [BXDatabaseObjectModel errorForMissingEntity: [self tableName] inSchema: [self schemaName]]];
	}
}

/**
 * \brief Set the database context.
 * \see #setFetchesAutomatically:
 */
- (void) setDatabaseContext: (BXDatabaseContext *) ctx
{
    if (ctx != _databaseContext)
    {
		NSNotificationCenter* nc = [ctx notificationCenter];
		//databaseContext may be nil here since we don't observe multiple contexts.
		[nc removeObserver: self name: kBXConnectionSuccessfulNotification object: _databaseContext];
		[nc removeObserver: self name: kBXGotDatabaseURINotification object: _databaseContext];
		
        _databaseContext = ctx;
		
		if (_databaseContext)
		{
			[self setEntityDescription: nil];
			[[_databaseContext notificationCenter] addObserver: self selector: @selector (_endConnecting:) name: kBXConnectionSuccessfulNotification object: _databaseContext];
			
			if (_fetchesAutomatically && (_tableName || _entityDescription) && [_databaseContext isConnected])
				[self fetch: nil];
		}
    }
}

- (void)setFetchesAutomatically:(BOOL)aBool {
	if (_fetchesAutomatically != aBool) {
		_fetchesAutomatically = aBool;
		if (nil != _databaseContext) {
			NSNotificationCenter* nc = [_databaseContext notificationCenter];
            if (_fetchesAutomatically) {
				[nc addObserver: self selector: @selector (_endConnecting:) name: kBXConnectionSuccessfulNotification object: _databaseContext];
            } else {
				[nc removeObserver: self name: kBXConnectionSuccessfulNotification object: _databaseContext];
            }
		}
	}
}

/**
 * \name Methods used by the IB plugin
 * \brief The controller will try to get an entity description when its database context
 *        based on these properties. This will occur when the context gets set and when 
 *        the context connects. If a class name has also been set, the controller will
 *        call NSClassFromString and set the entity's corresponding property.
 */

- (void)_endConnecting:(NSNotification *)notification {
    if (! _entityDescription) {
		[self prepareEntity];
    }
    if (_fetchesAutomatically) {
		[self fetch: nil];
    }
}

//Patch by henning & #macdev 2008-01-30
static BOOL IsKindOfClass (id self, Class class) {
	if (self == nil) 
		return NO; 
	else if ([self class] == class) 
		return YES; 
	else 
		return IsKindOfClass ([self superclass], class);
}
//End patch

- (void) setBXContent: (id) anObject
{
    BXAssertLog (nil == mBXContent || IsKindOfClass (anObject, [BXContainerProxy class]),
                   @"Expected anObject to be an instance of BXContainerProxy (was: %@).", 
                   [anObject class]);
	if (mBXContent != anObject)
	{
        mBXContent = anObject;
	}
}

- (id) BXContent
{
	return mBXContent;
}

/**
 * \brief Create a new object.
 *
 * Calls
 * -[BXDatabaseContext createObjectForEntity:withFieldValues:error:].
 * If the receiver's contentSet is bound to another BXSynchronizedArrayController using
 * a key that refers to a to-many relationship, the created object's foreign key values
 * will be set accordingly.
 * \param outError Error returned by the database. If NULL is passed and an error occurs,
 *                 BXDatabaseContext will raise an exception by default.
 * \return An autoreleased BXDatabaseObject.
 * \see #newObject
 */
- (id) createObject: (NSError **) outError
{
	if (!_entityDescription)
		[self prepareEntity];
	
	NSDictionary* fieldValues = [self valuesForBoundRelationship];
	mShouldAddToContent = (nil == fieldValues);
	return [_databaseContext createObjectForEntity:_entityDescription
								  withFieldValues: fieldValues error: outError];
}


- (NSDictionary *) valuesForBoundRelationship
{
	NSDictionary* retval = nil;
	if ([_contentBindingKey isEqualToString: @"contentSet"])
	{
		//We only check contentSet, because relationships cannot be bound to any other key.
		NSDictionary* bindingInfo = [self infoForBinding: @"contentSet"];
		id observedObject = [bindingInfo objectForKey: NSObservedObjectKey];
		id boundObject = [observedObject valueForKeyPath: [bindingInfo objectForKey: NSObservedKeyPathKey]];
		if ([boundObject BXIsRelationshipProxy])
		{
            //FIXME: many-to-many relationships aren't handled.
			BXRelationshipDescription* rel = [boundObject relationship];
			BXRelationshipDescription* inverse = [rel inverseRelationship];
			if (! [inverse isToMany])
			{
				retval = [NSDictionary dictionaryWithObject: [boundObject owner] forKey: inverse];
			}
		}
	}
	return retval;
}

- (void)setContentBindingKey:(NSString *)aKey {
	if (aKey != _contentBindingKey) {
        _contentBindingKey = [aKey copy];
        if (aKey.length > 0) {
            self.fetchesAutomatically = NO;
        }
	}
}

+ (NSSet *)keyPathsForValuesAffectingSelectedObjectIDs {
	return [NSSet setWithObject:NSStringFromSelector(@selector(selectedObjects))];
}

/**
 * \brief The Object IDs of the selected objects.
 */
- (NSArray *)selectedObjectIDs {
	return (id) [[[self selectedObjects] BX_Collect] objectID];
}

#pragma mark Overridden Methods
/**
 * \name Overridden methods
 * \brief Methods changed from NSArrayController's implementation.
 */
//@{
/**
 * \brief Exposed bindings
 *
 * managedObjectContext is removed from bindings exposed by the superclass.
 */
- (NSArray *)exposedBindings {
	NSMutableArray* retval = [[super exposedBindings] mutableCopy];
	[retval removeObject:NSStringFromSelector(@selector(managedObjectContext))];
	return [retval copy];
}

- (void) bind: (NSString *) binding toObject: (id) observableObject
  withKeyPath: (NSString *) keyPath options: (NSDictionary *) options
{
	if ([binding isEqualToString: @"contentSet"] || [binding isEqualToString: @"contentArray"])
		[self setContentBindingKey: binding];
	[super bind: binding toObject: observableObject withKeyPath: keyPath options: options];
}

- (void) unbind: (NSString *) binding
{
	[super unbind: binding];
	if ([binding isEqualToString: @"contentSet"] || [binding isEqualToString: @"contentArray"])
		[self setContentBindingKey: nil];
}

- (void) objectDidBeginEditing: (id) editor
{
	if (_locksRowsOnBeginEditing)
	{
		//This is a bit bad. Since we have bound one of our own attributes to 
		//one of our bindings, -commitEditing might get called recursively ad infinitum.
		//We prevent this by not starting to edit in this object; it doesn't happen
		//normally in 10.4, either.
		if (self != editor)
		{
			[self BXLockKey: nil status: kBXObjectLockedStatus editor: editor];
			[super objectDidBeginEditing: editor];
		}
	}
}

- (void) objectDidEndEditing: (id) editor
{
	if (_locksRowsOnBeginEditing)
	{
		//See -objectDidBeginEditing:.
		if (self != editor)
		{
			[super objectDidEndEditing: editor];
			[self BXUnlockKey: nil editor: editor];
		}
	}
}

/**
 * \brief Perform a fetch.
 *
 * Calls -fetchWithRequest:merge:error:. If an error occurs, an alert sheet or panel is displayed.
 * \param sender Ignored.
 */
- (void) fetch: (id) sender
{
    NSError* error = nil;
	[self fetchWithRequest: nil merge: NO error: &error];
    if (nil != error)
        [self BXHandleError: error];
}

/**
 * \brief Perform a fetch.
 *
 * Fetch objects from the database.
 * \param fetchReques Currently ignored. Pass nil.
 * \param merge Whether the content should be replaced. If the receiver already
 *              has a collection, it won't be re-fetched, because the collection's contents
 *              will be automatically updated.
 * \param error Error returned by the database. If NULL is passed and an error occurs,
 *              BXDatabaseContext will raise an exception by default.
 * \return      If the fetch was successful or it wasn't needed, the receiver will return YES.
 */
- (BOOL) fetchWithRequest: (NSFetchRequest *) fetchRequest merge: (BOOL) merge error: (NSError **) error
{
	if (! _entityDescription)
		[self prepareEntity];
	
    BOOL retval = NO;
	if (merge && nil != [self content])
	{
		//This should happen automatically. Currently we don't have an API to refresh an
		//automatically-updated collection.
		retval = YES;
	}
	else
	{
		id result = [_databaseContext executeFetchForEntity: _entityDescription
											 withPredicate: [self fetchPredicate]
										   returningFaults: NO
									   updateAutomatically: YES
													 error: error];

		[self setBXContent: result];
		[result setOwner: self];
		[result setKey: @"BXContent"];
		[self bind: @"contentArray" toObject: self withKeyPath: @"BXContent" options: nil];
	}
	
    return retval;
}

/**
 * \brief Create a new object.
 *
 * Calls #createObject:, which in turn calls 
 * -[BXDatabaseContext createObjectForEntity:withFieldValues:error:].
 * If an error occurs, an alert sheet or panel will be displayed.
 * If the receiver's contentSet is bound to another BXSynchronizedArrayController using
 * a key that refers to a to-many relationship, the created object's foreign key values
 * will be set accordingly. 
 * \return A retained BXDatabaseObject.
 */
- (id) newObject
{
    mChanging = YES;
    NSError* error = nil;
	id object = [self createObject: &error];
    if (nil != error) {
        [self BXHandleError: error];
    }
    mChanging = NO;
    return object;
}

- (void) insertObject: (id) object atArrangedObjectIndex: (NSUInteger) index
{
	if (mShouldAddToContent && _contentBindingKey && ![self BXContent])
	{
		//Super's implementation selects inserted objects.
		[super insertObject: object atArrangedObjectIndex: index];
	}
	else if ([self selectsInsertedObjects])
	{
		//Don't invoke super's implementation since it replaces BXContent.
		//-newObject creates the row already.
		[self setSelectedObjects: [NSArray arrayWithObject: object]];
	}
	mShouldAddToContent = YES;
}

/**
 * \brief Delete objects at specified indices.
 *
 * Deletes specified rows from the database. The objects will be marked deleted.
 * If an error occurs, an alert sheet or panel will be displayed.
 */
- (void) removeObjectsAtArrangedObjectIndexes: (NSIndexSet *) indexes
{
	if (0 < [indexes count])
	{
		NSError* error = nil;
		NSArray* objects = [[self arrangedObjects] objectsAtIndexes: indexes];
		BXEntityDescription* entity = [(BXDatabaseObject *) [objects lastObject] entity];
		ExpectV (entity);
		
		NSMutableArray* predicates = [NSMutableArray arrayWithCapacity: [objects count]];
		BXEnumerate (currentObject, e, [objects objectEnumerator])
		{
			BXAssertVoidReturn ([(BXDatabaseObject *) currentObject entity] == entity, 
								@"Expected entities to match. (%@, %@)", entity, [currentObject entityDescription]);
			[predicates addObject: [[(BXDatabaseObject *) currentObject objectID] predicate]];
		}
		
		NSPredicate* predicate = [NSCompoundPredicate orPredicateWithSubpredicates: predicates];
		[_databaseContext executeDeleteFromEntity: entity withPredicate: predicate error: &error];
		if (nil != error)
			[self BXHandleError: error];
	}
}

- (NSString *)entityName {
	return nil;
}

- (void)setEntityName:(NSString *)name {
}

- (Class)objectClass {
	return [_entityDescription databaseObjectClass];
}

- (void)setObjectClass:(Class)cls {
    if (! _entityDescription){
		[self prepareEntity];
    }
	[_entityDescription setDatabaseObjectClass: cls];
}

- (BOOL)usesLazyFetching {
    return NO;
}

- (void)setUsesLazyFetching:(BOOL)usesLazyFetching {
}

- (NSManagedObjectContext*)managedObjectContext {
    return nil;
}

- (void)setManagedObjectContext:(NSManagedObjectContext*)ctx {
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Don't change fetchesOnConnect in strings, or users' nibs stop working.
    [super encodeWithCoder: encoder];
    [encoder encodeBool:_fetchesAutomatically forKey: @"fetchesOnConnect"];
    [encoder encodeBool:_locksRowsOnBeginEditing forKey: @"locksRowsOnBeginEditing"];
    [encoder encodeObject:_tableName forKey: @"tableName"];
    [encoder encodeObject:_schemaName forKey: @"schemaName"];
    [encoder encodeObject:_databaseObjectClassName forKey: @"DBObjectClassName"];
    [encoder encodeObject:_contentBindingKey forKey: @"contentBindingKey"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self setAutomaticallyPreparesContent: NO];
        [self setEditable: YES];
        //Some reasonable default values for booleans to make existing nibs work.
        BOOL fetchOnConnect = NO;
        if ([decoder containsValueForKey: @"fetchesOnConnect"]) {
            fetchOnConnect = [decoder decodeBoolForKey: @"fetchesOnConnect"];
        }
        [self setFetchesAutomatically: fetchOnConnect];
        BOOL lockOnBeginEditing = YES;
        if ([decoder containsValueForKey: @"locksRowsOnBeginEditing"]) {
            lockOnBeginEditing = [decoder decodeBoolForKey: @"locksRowsOnBeginEditing"];
        }
        [self setLocksRowsOnBeginEditing: lockOnBeginEditing];
        [self setTableName:[decoder decodeObjectForKey: @"tableName"]];
        [self setSchemaName:[decoder decodeObjectForKey: @"schemaName"]];
        [self setContentBindingKey:[decoder decodeObjectForKey: @"contentBindingKey"]];
        [self setDatabaseObjectClassName:[decoder decodeObjectForKey: @"DBObjectClassName"]];
    }
    return self;
}

@end
