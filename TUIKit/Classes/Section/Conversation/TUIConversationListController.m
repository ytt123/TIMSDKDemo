//
//  TUIConversationListController.m
//  TXIMSDK_TUIKit_iOS
//
//  Created by annidyfeng on 2019/5/17.
//

#import "TUIConversationListController.h"
#import "TUIConversationCell.h"
#import "THeader.h"
#import "TUIKit.h"
#import "TUILocalStorage.h"
#import "TIMUserProfile+DataProvider.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "UIColor+TUIDarkMode.h"
#import "NSBundle+TUIKIT.h"
@import ImSDK;
#define GRTColor(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
static NSString *kConversationCell_ReuseId = @"TConversationCell";

@interface TUIConversationListController () <UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate>
@end

@implementation TUIConversationListController


- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];

    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupViews
{
    self.view.backgroundColor = [UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.backgroundColor = self.view.backgroundColor;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 8, 0);
    [_tableView registerClass:[TUIConversationCell class] forCellReuseIdentifier:kConversationCell_ReuseId];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];

    @weakify(self)
    [RACObserve(self.viewModel, dataList) subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.tableView reloadData];
    }];
}

- (TConversationListViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [TConversationListViewModel new];
    }
    return _viewModel;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.dataList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel.dataList[indexPath.row] heightOfWidth:Screen_Width];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TUILocalizableString(Delete);
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewRowAction * action1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"??????" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [tableView beginUpdates];
        TUIConversationCellData *conv = self.viewModel.dataList[indexPath.row];
        [self.viewModel removeData:conv];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
          
    }];
    action1. backgroundColor=GRTColor(0xf64e4b);
    
    
    TUIConversationCellData *conv = self.viewModel.dataList[indexPath.row];

    

    int unreadCount=conv.unreadCount;
    BOOL isOnTop =conv.isOnTop;
    
    UITableViewRowAction * action2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:unreadCount?@"????????????":@"????????????" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {

        [tableView beginUpdates];
        TUIConversationCellData *conv = self.viewModel.dataList[indexPath.row];
 
        if(unreadCount){
            conv.unreadCount=0;
        }else{
            conv.unreadCount=1;
        }
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
        
    }];
    action2. backgroundColor=GRTColor(0xf0913e);
    UITableViewRowAction * action3 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:isOnTop?@"????????????":@"????????????" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [tableView beginUpdates];
        TUIConversationCellData *conv = self.viewModel.dataList[indexPath.row];
 
        if(isOnTop){
            conv.isOnTop=false;
        }else{
            conv.isOnTop=true;
        }
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
    }];
    action3. backgroundColor=GRTColor(0x434343);
    return @[action1, action2, action3];

}
// - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
// {
//     if (editingStyle == UITableViewCellEditingStyleDelete) {
//         [tableView beginUpdates];
//         TUIConversationCellData *conv = self.viewModel.dataList[indexPath.row];
//         [self.viewModel removeData:conv];
//         [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
//         [tableView endUpdates];
//     }
// }

- (void)didSelectConversation:(TUIConversationCell *)cell
{
    if(_delegate && [_delegate respondsToSelector:@selector(conversationListController:didSelectConversation:)]){
        [_delegate conversationListController:self didSelectConversation:cell];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TUIConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:kConversationCell_ReuseId forIndexPath:indexPath];
    TUIConversationCellData *data = [self.viewModel.dataList objectAtIndex:indexPath.row];
    if (!data.cselector) {
        data.cselector = @selector(didSelectConversation:);
    }
    [cell fillWithData:data];

    //??????????????????????????????????????????cell?????????????????????????????????????????????????????????????????????????????????????????????
    cell.changeColorWhenTouched = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
           [cell setSeparatorInset:UIEdgeInsetsMake(0, 75, 0, 0)];
        if (indexPath.row == (self.viewModel.dataList.count - 1)) {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
    }

    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }

    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
