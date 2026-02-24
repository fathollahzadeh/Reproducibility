
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN Co.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.PostId IS NOT NULL THEN 1 END) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments Co ON P.Id = Co.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, U.DisplayName, P.CreationDate, P.Score, P.ViewCount
), FilteredPosts AS (
    SELECT 
        RP.* 
    FROM 
        RankedPosts RP
    WHERE 
        RP.ViewCount >= 1000 
        AND (RP.Tags LIKE '%SQL%' OR RP.Tags LIKE '%database%')
        AND RP.PostRank <= 3
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.OwnerDisplayName,
    FP.CreationDate,
    FP.Score,
    FP.ViewCount,
    FP.CommentCount,
    FP.VoteCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS RelatedTags
FROM 
    FilteredPosts FP
LEFT JOIN 
    Tags T ON FP.Tags LIKE '%' || T.TagName || '%'
GROUP BY 
    FP.PostId, FP.Title, FP.OwnerDisplayName, FP.CreationDate, FP.Score, FP.ViewCount, FP.CommentCount, FP.VoteCount
ORDER BY 
    FP.Score DESC;
