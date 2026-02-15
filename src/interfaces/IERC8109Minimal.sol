pragma solidity ^0.8.30;

interface IERC8109Minimal {
    error FunctionNotFound(bytes4 selector);

    event SetDiamondFacet(bytes4 indexed selector, address indexed delegate);

    function facetAddress(bytes4 selector) external view returns (address);

    struct FunctionFacetPair {
        bytes4 selector;
        address facet;
    }

    function functionFacetPairs() external view returns (FunctionFacetPair[] memory pairs);
}
