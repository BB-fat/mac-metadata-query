/**
 * A MDQueryItem represents a file search result.
 * The unit of time parameter is seconds.
 */
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
 * Search scope for MDQuery.
 * @link https://developer.apple.com/documentation/coreservices/file_metadata/mdquery/query_search_scope_keys?language=objc
 */
export enum MDQueryScope {
    Home = 'kMDQueryScopeHome',
    Computer = 'kMDQueryScopeComputer',
    Network = 'kMDQueryScopeNetwork',
    AllIndexed = 'kMDQueryScopeAllIndexed',
    ComputerIndexed = 'kMDQueryScopeComputerIndexed',
    NetworkIndexed = 'kMDQueryScopeNetworkIndexed'
}

/**
 * Quick search with MDQuery.
 * @param query The MDQuery expression.
 * @param scopes Search scopes.
 * @param maxResultCount The maximum number of results returned.
 */
export function mdQuery(option: {
    query: string;
    scopes?: string[];
    maxResultCount?: number;
}): Promise<MDQueryItem[]>;

// Pass this value to maxResultCount means do not limit the number of the results returned.
export const MDQueryResultCountNoLimit = 0;

/**
 * When a query is updated, update type will be returned in the callback function.
 */
export enum MDQueryUpdateType {
    Add,
    Change,
    Remove
}

/**
 * Core Services MDQuery wrapper.
 * The same tech used by Spotlight.
 * @link https://developer.apple.com/documentation/coreservices/file_metadata/mdquery?language=objc
 */
export declare class MDQuery {
    /**
     * @param query MDQuery expression.
     * @param scopes Search scopes.
     * @param maxResultCount The maximum number of results returned.
     */
    constructor(query: string, scopes: string[], maxResultCount: number);

    /**
     * Start query.
     * @param callback
     */
    start(callback: (data: MDQueryItem[]) => void): void;

    /**
     * Stop query.
     */
    stop(): void;

    /**
     * Watch query's updates.
     * @param callback 
     */
    watch(callback: (type: MDQueryUpdateType, items: MDQueryItem[]) => void): void;

    /**
     * Stop watch query's updates.
     */
    stopWatch(): void;
}
