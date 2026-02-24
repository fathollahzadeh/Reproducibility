
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.UpVoteCount,
        RP.DownVoteCount
    FROM RankedPosts RP
    WHERE RP.Rank <= 5 
),
PostsWithTags AS (
    SELECT 
        FP.PostId,
        FP.Title,
        FP.Body,
        FP.CreationDate,
        FP.OwnerDisplayName,
        FP.CommentCount,
        FP.UpVoteCount,
        FP.DownVoteCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM FilteredPosts FP
    LEFT JOIN Posts P ON FP.PostId = P.Id
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(P.Tags, '><')) AS TagName
    ) T ON TRUE
    GROUP BY FP.PostId, FP.Title, FP.Body, FP.CreationDate, FP.OwnerDisplayName, FP.CommentCount, FP.UpVoteCount, FP.DownVoteCount
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    OwnerDisplayName,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    Tags
FROM PostsWithTags
ORDER BY CreationDate DESC
LIMIT 10;
