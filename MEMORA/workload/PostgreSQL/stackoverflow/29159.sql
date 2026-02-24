
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2) ORDER BY p.Score DESC) AS Rank,
        SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2) AS Tag
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01' 
),
TopQnByTag AS (
    SELECT 
        rp.Tag,
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalBenchmark AS (
    SELECT 
        tq.Tag,
        tq.Title,
        tq.OwnerDisplayName,
        tq.CreationDate,
        cs.CommentCount,
        cs.LastCommentDate,
        CASE 
            WHEN cs.CommentCount > 10 THEN 'High Engagement'
            WHEN cs.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        TopQnByTag tq
    LEFT JOIN 
        CommentStats cs ON tq.PostId = cs.PostId
)
SELECT 
    Tag,
    Title,
    OwnerDisplayName,
    CreationDate,
    CommentCount,
    LastCommentDate,
    EngagementLevel
FROM 
    FinalBenchmark
ORDER BY 
    Tag, CreationDate;
