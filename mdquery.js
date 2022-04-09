const {
    MDQuery,
} = require('node-gyp-build')(__dirname);

const mdQueryImpl = (option) => {
    const { query, scopes, maxResultCount } = option;
    const mdQuery = new MDQuery(query, scopes ?? [MDQueryScope.Home], maxResultCount ?? 0);
    return new Promise((resolve) => {
        mdQuery.start((result) => resolve(result));
    });
};

const MDQueryScope = {
    Home: 'kMDQueryScopeHome',
    Computer: 'kMDQueryScopeComputer',
    Network: 'kMDQueryScopeNetwork',
    AllIndexed: 'kMDQueryScopeAllIndexed',
    ComputerIndexed: 'kMDQueryScopeComputerIndexed',
    NetworkIndexed: 'kMDQueryScopeNetworkIndexed',
};

const MDQueryUpdateType = {
    Add: 0,
    Change: 1,
    Remove: 2,
};

module.exports = {
    mdQuery: mdQueryImpl,
    MDQuery,
    MDQueryScope,
    MDQueryResultCountNoLimit: 0,
    MDQueryUpdateType,
};
