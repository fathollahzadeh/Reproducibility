
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        rp.CommentCount,
        CASE 
            WHEN rp.Score >= 100 THEN 'High Score'
            WHEN rp.Score >= 50 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.ScoreRank = 1
), 
AggregateData AS (
    SELECT
        ScoreCategory,
        COUNT(*) AS PostCount,
        AVG(OwnerReputation) AS AvgReputation,
        MAX(ViewCount) AS MaxViewCount,
        MIN(COALESCE(CommentCount, 0)) AS MinCommentCount
    FROM 
        PostStats
    GROUP BY 
        ScoreCategory
)
SELECT 
    ad.ScoreCategory,
    ad.PostCount,
    ad.AvgReputation,
    ad.MaxViewCount,
    ad.MinCommentCount,
    CASE 
        WHEN ad.PostCount > 0 THEN ROUND(AVG(ad.AvgReputation) OVER (), 2)
        ELSE NULL 
    END AS OverallAvgReputation
FROM 
    AggregateData ad
ORDER BY 
    CASE ad.ScoreCategory
        WHEN 'High Score' THEN 1
        WHEN 'Medium Score' THEN 2
        WHEN 'Low Score' THEN 3
    END;
