
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS OwnerPostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, LENGTH(P.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags T ON T.TagName = tag
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.ViewCount, P.Score
),
FilteredPosts AS (
    SELECT 
        RP.* 
    FROM 
        RankedPosts RP
    WHERE 
        RP.CommentCount > 10 
        AND RP.OwnerPostRank <= 3 
)
SELECT 
    FP.Title,
    FP.OwnerDisplayName,
    FP.CreationDate,
    FP.ViewCount,
    FP.Score,
    FP.CommentCount,
    FP.Tags,
    CASE 
        WHEN FP.Score > 100 THEN 'Highly Rated'
        WHEN FP.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Needs Improvement'
    END AS PostQuality
FROM 
    FilteredPosts FP
ORDER BY 
    FP.Score DESC, FP.CreationDate DESC;
