const { MDQueryScope, MDQuery,
    MDQueryResultCountNoLimit, } = require('./mdquery');

const MDItemKey = {
    DisplayName: 'kMDItemDisplayName',
    FSName: 'kMDItemFSName',
    ModificationDate: 'kMDItemContentModificationDate',
    CreationDate: 'kMDItemContentCreationDate',
    LastUsedDate: 'kMDItemLastUsedDate',
    Size: 'kMDItemFSSize',
    ContentType: 'kMDItemContentType',
};

const timestampToMDDate = (timestamp) =>
    `$time.iso(${new Date(timestamp * 1000).toISOString()})`;

const rangeMDQueryExpression = (key, min, max) =>
    `InRange(${key}, ${min}, ${max})`;

const mdqCompareType_operatorMap = {
    greaterThen: '>',
    lessThen: '<',
    equal: '==',
    greaterOrEqual: '>=',
    lessOrEqual: '<=',
};

class MDQueryRunner {
    group = [];

    get expression() {
        return this.group.length > 0 ? `(${this.group.join('&&')})` : '';
    }
    
    getOptions(options) {
        if (options === undefined) {
            return {
                scopes: [MDQueryScope.Home],
                maxResultCount: MDQueryResultCountNoLimit,
            };
        }
        return options;
    }

    query;

    async run(options) {
        const { scopes, maxResultCount } = this.getOptions(options);

        this.stop();

        this.query = new MDQuery(this.expression, scopes, maxResultCount);

        const start = () => {
            return new Promise((resolve) => {
                this.query?.start((data) => resolve(data));
            });
        };

        let result = await start();

        if (this.listener) {
            this.query.watch(this.listener);
        }

        result.forEach((e) => {
            if (e.path.includes('/System/Volumes/Data')) {
                e.path = e.path.replace('/System/Volumes/Data', '');
            }
        });

        return result;
    }

    listener;

    watch(listener) {
        this.listener = listener;
        this.query?.watch(listener);
    }

    stopWatch() {
        this.query?.stopWatch();
        this.listener = undefined;
    }

    stop() {
        this.query?.stop();
        this.query = undefined;
    }

    nameLike(nameLike) {
        this.group.push(`${MDItemKey.DisplayName} == "*${nameLike}*"c`);
        return this;
    }

    nameIs(name) {
        this.group.push(`${MDItemKey.DisplayName} == "${name}"c`);
        return this;
    }

    time(timeKey, compareType, value) {
        this.group.push(
            `${timeKey} ${mdqCompareType_operatorMap[compareType]} ${timestampToMDDate(value)}`
        );
        return this;
    }

    size(compareType, value) {
        this.group.push(`${MDItemKey.Size} ${mdqCompareType_operatorMap[compareType]} ${value}`);
        return this;
    }

    isDir(is) {
        this.group.push(`${MDItemKey.ContentType} ${is ? '=' : '!'}= "public.folder"`);
        return this;
    }

    isType(type) {
        this.group.push(`${MDItemKey.FSName} == "*.${type}"c`);
        return this;
    }

    inType(types) {
        this.group.push(`(${types.map((t) => `${MDItemKey.FSName} == "*.${t}"c`).join('||')})`);
        return this;
    }

    contentTypeIs(type) {
        this.group.push(`${MDItemKey.ContentType} == "${type}"`);
        return this;
    }

    and(other) {
        const myExp = this.expression;
        const otherExp = other.expression;
        if (myExp.length !== 0 && otherExp.length !== 0) {
            this.group = [`(${myExp} && ${otherExp})`];
        } else if (otherExp.length !== 0) {
            this.group = [otherExp];
        }

        return this;
    }

    or(other) {
        const myExp = this.expression;
        const otherExp = other.expression;
        if (myExp.length !== 0 && otherExp.length !== 0) {
            this.group = [`(${myExp} || ${otherExp})`];
        } else if (otherExp.length !== 0) {
            this.group = [otherExp];
        }

        return this;
    }

    static merge(runners, isAnd) {
        const runner = new MDQueryRunner();
        if (isAnd) {
            runners.forEach((e) => runner.and(e));
        } else {
            runners.forEach((e) => runner.or(e));
        }
        return runner;
    }
}

module.exports = {
    MDItemKey,
    timestampToMDDate,
    rangeMDQueryExpression,
    MDQueryRunner,
};