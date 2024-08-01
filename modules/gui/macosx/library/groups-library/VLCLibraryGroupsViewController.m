/*****************************************************************************
 * VLCLibraryGroupsViewController.m: MacOS X interface module
 *****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
 *
 * Authors: Claudio Cambra <developer@claudiocambra.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCLibraryGroupsViewController.h"

#import "library/VLCLibraryCollectionViewDelegate.h"
#import "library/VLCLibraryCollectionViewFlowLayout.h"
#import "library/VLCLibraryCollectionViewItem.h"
#import "library/VLCLibraryCollectionViewMediaItemSupplementaryDetailView.h"
#import "library/VLCLibraryCollectionViewSupplementaryElementView.h"
#import "library/VLCLibraryController.h"
#import "library/VLCLibraryMasterDetailViewTableViewDelegate.h"
#import "library/VLCLibraryModel.h"
#import "library/VLCLibraryTableCellView.h"
#import "library/VLCLibraryTableView.h"
#import "library/VLCLibraryUIUnits.h"
#import "library/VLCLibraryWindow.h"

#import "library/groups-library/VLCLibraryGroupsDataSource.h"

#import "main/VLCMain.h"

@implementation VLCLibraryGroupsViewController

- (instancetype)initWithLibraryWindow:(VLCLibraryWindow *)libraryWindow
{
    self = [super init];
    if (self) {
        [self setupPropertiesFromLibraryWindow:libraryWindow];
        [self setupDataSource];
        [self setupGridViewModeViews];
        [self setupListViewModeViews];
    }
    return self;
}

- (void)setupPropertiesFromLibraryWindow:(VLCLibraryWindow *)libraryWindow
{
    NSParameterAssert(libraryWindow);
    _libraryWindow = libraryWindow;
    _libraryTargetView = libraryWindow.libraryTargetView;
    _emptyLibraryView = libraryWindow.emptyLibraryView;
    _placeholderImageView = libraryWindow.placeholderImageView;
    _placeholderLabel = libraryWindow.placeholderLabel;
}

- (void)setupDataSource
{
    _dataSource = [[VLCLibraryGroupsDataSource alloc] init];
    self.dataSource.libraryModel = VLCMain.sharedInstance.libraryController.libraryModel;
}

- (void)setupGridViewModeViews
{
    _collectionViewScrollView = [[NSScrollView alloc] init];
    _collectionView = [[NSCollectionView alloc] init];

    self.collectionViewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;

    self.collectionViewScrollView.hasHorizontalScroller = NO;
    self.collectionViewScrollView.borderType = NSNoBorder;
    self.collectionViewScrollView.automaticallyAdjustsContentInsets = NO;
    self.collectionViewScrollView.contentInsets =
        VLCLibraryUIUnits.libraryViewScrollViewContentInsets;
    self.collectionViewScrollView.scrollerInsets =
        VLCLibraryUIUnits.libraryViewScrollViewScrollerInsets;
    self.collectionViewScrollView.documentView = self.collectionView;

    const CGFloat collectionItemSpacing = VLCLibraryUIUnits.collectionViewItemSpacing;
    const NSEdgeInsets collectionViewSectionInset = VLCLibraryUIUnits.collectionViewSectionInsets;

    VLCLibraryCollectionViewFlowLayout * const collectionViewLayout =
        [[VLCLibraryCollectionViewFlowLayout alloc] init];
    collectionViewLayout.headerReferenceSize =
        VLCLibraryCollectionViewSupplementaryElementView.defaultHeaderSize;
    collectionViewLayout.minimumLineSpacing = collectionItemSpacing;
    collectionViewLayout.minimumInteritemSpacing = collectionItemSpacing;
    collectionViewLayout.sectionInset = collectionViewSectionInset;
    self.collectionView.collectionViewLayout = collectionViewLayout;

    _collectionViewDelegate = [[VLCLibraryCollectionViewDelegate alloc] init];
    self.collectionViewDelegate.itemsAspectRatio = VLCLibraryCollectionViewItemAspectRatioVideoItem;
    self.collectionViewDelegate.staticItemSize = VLCLibraryCollectionViewItem.defaultVideoItemSize;
    self.collectionView.delegate = self.collectionViewDelegate;

    [self.collectionView registerClass:VLCLibraryCollectionViewItem.class
                 forItemWithIdentifier:VLCLibraryCellIdentifier];

    [self.collectionView registerClass:VLCLibraryCollectionViewSupplementaryElementView.class
            forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader
                        withIdentifier:VLCLibrarySupplementaryElementViewIdentifier];

    NSString * const mediaItemSupplementaryDetailViewString =
        NSStringFromClass(VLCLibraryCollectionViewMediaItemSupplementaryDetailView.class);
    NSNib * const mediaItemSupplementaryDetailViewNib =
        [[NSNib alloc] initWithNibNamed:mediaItemSupplementaryDetailViewString bundle:nil];

    [self.collectionView registerNib:mediaItemSupplementaryDetailViewNib
          forSupplementaryViewOfKind:VLCLibraryCollectionViewMediaItemSupplementaryDetailViewKind
                      withIdentifier:VLCLibraryCollectionViewMediaItemSupplementaryDetailViewIdentifier];

    self.collectionView.delegate = self.collectionViewDelegate;
}

- (void)setupListViewModeViews
{
    _groupsTableViewScrollView = [[NSScrollView alloc] init];
    _selectedGroupTableViewScrollView = [[NSScrollView alloc] init];
    _tableViewDelegate = [[VLCLibraryMasterDetailViewTableViewDelegate alloc] init];
    _groupsTableView = [[VLCLibraryTableView alloc] init];
    _selectedGroupTableView = [[VLCLibraryTableView alloc] init];
    _listViewSplitView = [[NSSplitView alloc] init];

    self.groupsTableViewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedGroupTableViewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.listViewSplitView.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedGroupTableView.translatesAutoresizingMaskIntoConstraints = NO;

    const NSEdgeInsets defaultInsets = VLCLibraryUIUnits.libraryViewScrollViewContentInsets;
    const NSEdgeInsets scrollerInsets = VLCLibraryUIUnits.libraryViewScrollViewScrollerInsets;

    self.groupsTableViewScrollView.hasHorizontalScroller = NO;
    self.groupsTableViewScrollView.borderType = NSNoBorder;
    self.groupsTableViewScrollView.automaticallyAdjustsContentInsets = NO;
    self.groupsTableViewScrollView.contentInsets = defaultInsets;
    self.groupsTableViewScrollView.scrollerInsets = scrollerInsets;

    self.selectedGroupTableViewScrollView.hasHorizontalScroller = NO;
    self.selectedGroupTableViewScrollView.borderType = NSNoBorder;
    self.selectedGroupTableViewScrollView.automaticallyAdjustsContentInsets = NO;
    self.selectedGroupTableViewScrollView.contentInsets = defaultInsets;
    self.selectedGroupTableViewScrollView.scrollerInsets = scrollerInsets;

    self.groupsTableViewScrollView.documentView = self.groupsTableView;
    self.selectedGroupTableViewScrollView.documentView = self.selectedGroupTableView;

    self.listViewSplitView.vertical = YES;
    self.listViewSplitView.dividerStyle = NSSplitViewDividerStyleThin;
    [self.listViewSplitView addArrangedSubview:self.groupsTableViewScrollView];
    [self.listViewSplitView addArrangedSubview:self.selectedGroupTableViewScrollView];

    NSTableColumn * const groupsColumn = [[NSTableColumn alloc] initWithIdentifier:@"groups"];
    NSTableColumn * const selectedGroupColumn =
        [[NSTableColumn alloc] initWithIdentifier:@"selectedGroup"];

    [self.groupsTableView addTableColumn:groupsColumn];
    [self.selectedGroupTableView addTableColumn:selectedGroupColumn];

    NSNib * const tableCellViewNib = 
        [[NSNib alloc] initWithNibNamed:NSStringFromClass(VLCLibraryTableCellView.class)
                                 bundle:nil];
    [self.groupsTableView registerNib:tableCellViewNib
                        forIdentifier:@"VLCLibraryTableViewCellIdentifier"];
    [self.selectedGroupTableView registerNib:tableCellViewNib
                               forIdentifier:@"VLCLibraryTableViewCellIdentifier"];

    self.groupsTableView.headerView = nil;
    self.selectedGroupTableView.headerView = nil;

    self.groupsTableView.rowHeight = VLCLibraryUIUnits.mediumTableViewRowHeight;
    self.selectedGroupTableView.rowHeight = VLCLibraryUIUnits.mediumTableViewRowHeight;

    self.groupsTableView.delegate = self.tableViewDelegate;
    self.selectedGroupTableView.delegate = self.tableViewDelegate;
}

@end
