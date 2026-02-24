
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
TagsSummary AS (
    SELECT 
        Tags.TagName,
        COUNT(P.Id) AS TotalPosts
    FROM 
        Tags
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        Tags.TagName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    COALESCE(PS.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(PS.TotalDownvotes, 0) AS TotalDownvotes,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    TS.TagName,
    TS.TotalPosts
FROM 
    RankedPosts RP
LEFT JOIN 
    PostStats PS ON RP.PostId = PS.PostId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    TagsSummary TS ON RP.PostId IN (SELECT P.Id FROM Posts P WHERE P.Tags LIKE '%' || TS.TagName || '%')
WHERE 
    RP.PostRank = 1
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;
