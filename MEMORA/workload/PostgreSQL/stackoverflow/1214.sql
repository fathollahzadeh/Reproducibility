WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId = 10
    GROUP BY 
        PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.AnswerCount,
    PT.TagName,
    COALESCE(CP.CloseVoteCount, 0) AS CloseVoteCount,
    CASE 
        WHEN RP.OwnerReputation > 1000 THEN 'High Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    PopularTags PT ON RP.Title ILIKE '%' || PT.TagName || '%'
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.RowNum = 1
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC
LIMIT 50;