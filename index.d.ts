export interface MDQueryItem {
    isDir: boolean;
    path: string;
    extension: string;

    createTime: number;
    lastModifyTime: number;
    lastUsedTime?: number;

    bundleIdentifier?: string;
    version?: string;
}

/**
 * @param query
 * @param scopes 检索范围，默认为空即全盘搜索
 * @param maxResultCount 最大结果数量，0不限制
 * @see mdQueryImpl
 */
export function mdQuery(option: {
    query: string;
    scopes?: string[];
    maxResultCount?: number;
}): Promise<MDQueryItem[]>;

export enum MDQueryScope {
    Home = 'kMDQueryScopeHome',
    Computer = 'kMDQueryScopeComputer',
    Network = 'kMDQueryScopeNetwork',
    AllIndexed = 'kMDQueryScopeAllIndexed',
    ComputerIndexed = 'kMDQueryScopeComputerIndexed',
    NetworkIndexed = 'kMDQueryScopeNetworkIndexed'
}

export const MDQueryResultCountNoLimit = 0;

export enum MDQueryUpdateType {
    Add,
    Change,
    Remove
}

export declare class MDQuery {
    constructor(query: string, scopes: string[], maxResultCount: number);
    start(callback: (data: MDQueryItem[]) => void): void;

    watch(callback: (type: MDQueryUpdateType, items: MDQueryItem[]) => void): void;
    stopWatch(): void;

    stop(): void;
}
