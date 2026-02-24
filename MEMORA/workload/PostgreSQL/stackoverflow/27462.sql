
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Comments c 
             WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '> <')) AS t(TagName) ON true
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
RecentPostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(*) FILTER (WHERE p.Score > 0) AS PositiveVotes,
        COUNT(*) FILTER (WHERE p.Score < 0) AS NegativeVotes,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.CreationDate) AS LastInteraction
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.CommentCount,
        rps.PositiveVotes,
        rps.NegativeVotes,
        rps.AvgViewCount,
        rps.LastInteraction,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        RecentPostStatistics rps ON rp.PostId = rps.PostId
    WHERE 
        rp.rn = 1 
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    Tags,
    CommentCount,
    PositiveVotes,
    NegativeVotes,
    AvgViewCount,
    LastInteraction,
    ScoreCategory
FROM 
    FinalResults
ORDER BY 
    LastInteraction DESC
LIMIT 100;
