Everything after the last release header should be ignored and empty lines should be ignored. 
To test that, let's write a changelog with a bunch of empty lines and a bunch of lines after the last release header.

    $ cat > CHANGE.md << EOF \
    > \
    > ## unreleased\
    > \
    > \
    > ### Added\
    > \
    > - added something nice\
    > ## 12.14.2\
    > some strange line\
    > ## Changed\
    > - broke everything\
    > \
    > \
    > ## Remomved\
    > - and then removed everything\
    > another strange line\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    12.15.0
    Info: The change has been tagged as a minor change.


If there are only items in "Fixed" and/or "Security", it should be a patch.

    $ cat > CHANGE.md << EOF \
    > ## unreleased\
    > ### Fixed\
    > - fixed me a drink while coding this.\
    > ## 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    12.14.3
    Info: The change has been tagged as a patch.

If there are (also) items in "Added" and/or "Deprecated", it should be a minor change.

    $ cat > CHANGE.md << EOF \
    > ## unreleased\
    > ### Security\
    > - digged some security hole\
    > ### Added\
    > - added something nice\
    > ## 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    12.15.0
    Info: The change has been tagged as a minor change.

If there are (also) items in "Removed" and possibly also in "Changed", it should be a major change.

    $ cat > CHANGE.md << EOF \
    > ## unreleased\
    > ### Removed\
    > - removed the API entirely\
    > ### Changed\
    > - given any part of the API, I changed that part \
    > ## 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    13.0.0
    Info: The change has been tagged as a major change .

It's also possible to choose different header types.

    $ cat > CHANGE.md << EOF \
    > # unreleased\
    > ##### Removed\
    > - removed the API entirely\
    > ##### Changed\
    > - given any part of the API, I changed that part \
    > # 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    13.0.0
    Info: The change has been tagged as a major change .

And there's a certain flexibility witht the last release format.

    $ cat > CHANGE.md << EOF \
    > # unreleased\
    > ##### Removed\
    > - removed the API entirely\
    > ##### Changed\
    > - given any part of the API, I changed that part \
    > # Release 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    13.0.0
    Info: The change has been tagged as a major change .

If there are items in "Changed", but no items in "Removed" (hence, it's not clear if it's a major change), it should throw an error.

    $ cat > CHANGE.md << EOF \
    > ## unreleased\
    > ### Added\
    > - added something nice\
    > ### Changed\
    > - changed something that's totally breaking unless it's not\
    > ## 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    Error: Changes listed under the `Changed` header leave too much room for interpretation to automatically deduce the semantic change. If it wasn't for those items, we'd suggest to tag the new version as a minor change.
    [8]

It doesn't matter if all possible headers are listed (some of them without items) -as done in the following- or only the ones with items -as done before.

    $ cat > CHANGE.md << EOF \
    > ## unreleased\
    > ### Added\
    > ### Changed\
    > ### Deprecated\
    > ### Fixed\
    > - I fixed me a drink while coding.\
    > ### Removed\
    > ### Security\
    > ## 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    12.14.3
    Info: The change has been tagged as a patch.

If there's any header that's none of the standard headers, the user should be warned.

    $ cat > CHANGE.md << EOF \
    > ## unreleased\
    > ### Added\
    > ### Changed\
    > ### Deprecated\
    > ### Fixed\
    > ### Removed\
    > ### Security\
    > - digged some security hole\
    > ### Chocolate\
    > - chocolate is nice\
    > ## 12.14.2\
    > EOF
    $ ochangelog print-version-number "CHANGE.md"
    12.14.3
    Info: The change has been tagged as a patch.
    Warning: Header "Chocolate" has been ignored: either its header type doesn't match the previous ones or
      its content doesn't match any of the changelog standard headers: Added, Changed, Deprecated, Fixed, Removed, Security.
