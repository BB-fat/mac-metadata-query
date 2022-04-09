# mac-metadata-query
A better way for electron APPs  searching files on Mac.

## Usage

It is recommended to use MDQueryRunner. Here is an example of searching by filename.

```js
const { MDQueryRunner, MDQueryScope } = require('mac-metadata-query');
const runner = new MDQueryRunner();
const results = await runner.nameLike('test').run();
```

MDQueryRunner supports chained calls.

```js
const { MDQueryRunner, MDQueryScope } = require('mac-metadata-query');

const runner = new MDQueryRunner();
const results = await runner.nameLike('test')
                            .isDir(false)
                            .isType('ppt')
                            .run();
```

You can combine multiple MDQueryRunners.

```js
const { MDQueryRunner, MDQueryScope } = require('mac-metadata-query');

const runner1 = new MDQueryRunner().nameLike('test').isDir(false);
const runner2 = new MDQueryRunner().isType('ppt');
const results = await runner1.and(runner2).run();
```

You can listen to a query result update.

```js
const { MDQueryRunner } = require('mac-metadata-query');

const runner = new MDQueryRunner().nameLike('test').isDir(false);
runner.run();
runner.watch((type, items) => {
    console.log(`Detect mdquery updates. Type:${type} Items:${JSON.stringify(items)}`);
});
```

------

If you have more customized query requirements, you can inherit MDQueryRunner and implement more methods or use the MDQuery object directly.

To operate MDQuery in a lower-level way, you can use the mdQuery function directly.

```typescript
import { mdQuery, MDQueryScope, MDQueryItem } from 'mac-metadata-query';

function searchFileWithName(name: string): Promise<MDQueryItem[]> {
    return mdQuery({
        query: `kMDItemDisplayName == "${name}"`,
        scopes: [MDQueryScope.Home]
    });
}
```

Or use a more complex MDQuery object:

```typescript
import { MDQuery, MDQueryResultCountNoLimit, MDQueryScope } from 'mac-metadata-query';

const name = 'test.c';
const query = new MDQuery(`kMDItemDisplayName == "${name}"`, [MDQueryScope.Home], MDQueryResultCountNoLimit);
query.start((data) => {
    console.log(data);
});
```

### Query

The query parameter is an expression in NSMetadataQuery.

An expression consists of MDItemAttribute, comparison operators, and values.

For example:`kMDItemDisplayName == "test.c"`This means to find all files whose filename is test.c.

If you want MDQuery to be case insensitive, write your expression like this: `kMDItemDisplayName == "test.c"c`

The syntax here is inconsistent with the [official document](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html#//apple_ref/doc/uid/TP40001849-CJBEJBHH), **there may also be other outdated sections of the official documentation.**

See this document for all supported MDItemAttribute: https://developer.apple.com/library/archive/documentation/CoreServices/Reference/MetadataAttributesRef/Reference/CommonAttrs.html#//apple_ref/doc/uid/TP40001694-SW1

**Be careful, some MDItemAttribute can't be used in query, such as kMDItemPath.**

Multiple expressions can be concatenated with && or || operator.

For more expression syntax rules, see the [official documentation](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html#//apple_ref/doc/uid/TP40001849-CJBEJBHH).

### Scopes

The MDQuery search scopes is an array of strings, which the elements can be some keys or directory paths. About keys, see:https://developer.apple.com/documentation/coreservices/file_metadata/mdquery/query_search_scope_keys?language=objc

**Note that if you pass some directory paths to a search scopes array, the operating system may need to ask user for permissions.**

### About Updates

* You should call `watch` after query starts.

* If the query is stopped, watch updates will also stop.

* The `item` parameter in the callback function is the current metadata of the file.

  This means that if the file is renamed or moved, you cannot know their original value.

* MDQueryItem may be incomplete in callback function of the file moved to trash.

* If user use the terminal to operate the file, there is a certain probability that the callback function will not be triggered.

## Reference

[File Metadata Query Expression Syntax](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html#//apple_ref/doc/uid/TP40001849-CJBEJBHH)

[Spotlight Metadata Attributes](https://developer.apple.com/library/archive/documentation/CoreServices/Reference/MetadataAttributesRef/Reference/CommonAttrs.html#//apple_ref/doc/uid/TP40001694-SW1)

[Query Search Scope Keys](https://developer.apple.com/documentation/coreservices/file_metadata/mdquery/query_search_scope_keys?language=objc)

## TODO
* Unit test.
* Example.
