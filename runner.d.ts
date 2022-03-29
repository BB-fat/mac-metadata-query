/* eslint-disable @typescript-eslint/naming-convention */
import {
    MDQueryItem,
    MDQueryUpdateType,
} from './mdquery';

/**
 * Commonly used Spotlight Metadata attribute keys.
 * You can find the complete list here.
 * https://developer.apple.com/library/archive/documentation/CoreServices/Reference/MetadataAttributesRef/Reference/CommonAttrs.html#//apple_ref/doc/uid/TP40001694-SW1
 */
export enum MDItemKey {
    DisplayName = 'kMDItemDisplayName',
    FSName = 'kMDItemFSName',
    ModificationDate = 'kMDItemContentModificationDate',
    CreationDate = 'kMDItemContentCreationDate',
    LastUsedDate = 'kMDItemLastUsedDate',
    Size = 'kMDItemFSSize',
    ContentType = 'kMDItemContentType',
}

/**
 * Convert seconds timestamp to time that can be used directly in MDQuery expressions.
 * @param timestamp
 */
export declare function timestampToMDDate(timestamp: number): string;

/**
 * Describe a value in a range.
 * @param key
 * @param min
 * @param max
 */
export declare function rangeMDQueryExpression(key: MDItemKey, min: number, max: number): string;

export type MDQCompareType = 'greaterThen' | 'lessThen' | 'equal' | 'greaterOrEqual' | 'lessOrEqual';

export type MDQueryUpdateListener = (type: MDQueryUpdateType, items: MDQueryItem[]) => void;

export declare class MDQueryRunner {

    /**
     * The actual executed MDQuery expression.
     */
    public get expression(): string;

    public run(options?: {
        scopes: string[];
        maxResultCount: number;
    }): Promise<MDQueryItem[]>;

    public stop(): void;

    /**
     * Listen for an MDQuery update event.
     * @param listener 
     */
    public watch(listener: MDQueryUpdateListener): void;

    public stopWatch(): void;

    /**
     * Add wildcards to the left and right of the query to match the file name. Not case sensitive.
     * @param nameLike 
     */
    public nameLike(nameLike: string): MDQueryRunner;

    /**
     * Exactly match filename.
     * @param name 
     */
    public nameIs(name: string): MDQueryRunner;

    public time(timeKey: MDItemKey.CreationDate | MDItemKey.ModificationDate | MDItemKey.LastUsedDate, compareType: MDQCompareType, value: number): MDQueryRunner;

    /**
     * Limit file size in bytes.
     * @param compareType 
     * @param value 
     */
    public size(compareType: MDQCompareType, value: number): MDQueryRunner;

    public isDir(is: boolean): MDQueryRunner;

    public isType(type: string): MDQueryRunner;

    public inType(types: string[]): MDQueryRunner;

    public contentTypeIs(type: string): MDQueryRunner;


    public and(other: MDQueryRunner): MDQueryRunner;

    public or(other: MDQueryRunner): MDQueryRunner;


    public static merge(runners: MDQueryRunner[], isAnd: boolean): MDQueryRunner;
}