WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        PHT.CreationDate AS LastEditDate,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PHT ON p.Id = PHT.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Tags IS NOT NULL
)
SELECT 
    RP.PostId, 
    RP.Title, 
    RP.Body,
    RP.Tags,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.OwnerDisplayName,
    RP.LastEditDate,
    CASE 
        WHEN RP.RankByViews <= 5 THEN 'Top Viewed'
        WHEN RP.RankByScore <= 5 THEN 'Top Scored'
        ELSE 'Other' 
    END AS RankingCategory
FROM 
    RankedPosts RP
WHERE 
    RP.RankByViews <= 5 OR RP.RankByScore <= 5
ORDER BY 
    RP.RankByViews, RP.RankByScore;