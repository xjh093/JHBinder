//
//  JHBindingNode.m
//  Haomissyou
//
//  Created by Haomissyou on 8/25/26.
//

#import "JHBindingNode.h"
#import "NSObject+JHBind.h"

@interface JHBindingNode ()
@property (nonatomic, copy, readwrite) NSString *nodeID;
@end

@implementation JHBindingNode

// MARK: - 普通属性节点（KVO）

- (instancetype)initWithTarget:(id)target
                       keyPath:(NSString *)keyPath
                     direction:(JHBindDirection)direction
                  convertBlock:(nullable JHConvertBlock)convertBlock {
    self = [super init];
    if (self) {
        self.target = target;
        self.keyPath = keyPath;
        self.targetHash = [(NSObject *)target jh_hash];
        self.direction = direction;
        self.convertBlock = convertBlock;
        self.isUIControl = NO;
        self.controlEvent = UIControlEventValueChanged;
        self.nodeID = [NSString stringWithFormat:@"%@_%@", self.targetHash, keyPath];
    }
    return self;
}

// MARK: - UIControl 节点（Target-Action）

- (instancetype)initWithTarget:(id)target
                       keyPath:(NSString *)keyPath
                  controlEvent:(UIControlEvents)controlEvent
                     direction:(JHBindDirection)direction
                  convertBlock:(nullable JHConvertBlock)convertBlock {
    self = [super init];
    if (self) {
        self.target = target;
        self.keyPath = keyPath;
        self.targetHash = [(NSObject *)target jh_hash];
        self.direction = direction;
        self.convertBlock = convertBlock;
        self.isUIControl = YES;
        self.controlEvent = controlEvent;
        self.nodeID = [NSString stringWithFormat:@"%@_%@", self.targetHash, keyPath];
    }
    return self;
}

// MARK: - 纯 block 订阅节点

+ (instancetype)nodeWithOutBlock:(JHOutBlock)outBlock key:(NSString *)key {
    JHBindingNode *node = [[JHBindingNode alloc] init];
    node.direction = JHBindDirectionReceive;
    node.outBlock = outBlock;
    // 无 target，nodeID 用 key 标识，确保唯一性
    node.nodeID = [NSString stringWithFormat:@"block_%@", key];
    node.targetHash = node.nodeID;
    node.keyPath = @"";
    node.isUIControl = NO;
    return node;
}

@end
