WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
        AND p.Score > 0
), 
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankScore,
        COALESCE(b.UserId, -1) AS BadgeHolderId,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.RankScore <= 5
), 
PostAnalytics AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.ViewCount,
        trp.Score,
        trp.RankScore,
        COALESCE((SELECT MAX(p2.ViewCount) FROM Posts p2 WHERE p2.Id = trp.PostId AND p2.ViewCount IS NOT NULL), 0) AS MaxViewCount,
        CASE 
            WHEN trp.BadgeHolderId IS NOT NULL THEN 'Has Badge'
            ELSE 'No Badge'
        END AS BadgeStatus
    FROM 
        TopRankedPosts trp
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.RankScore,
    pa.MaxViewCount,
    pa.BadgeStatus,
    CASE 
        WHEN pa.Score > 10 THEN 'Highly Engaged'
        WHEN pa.Score BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
FROM 
    PostAnalytics pa
LEFT JOIN 
    Posts p ON pa.PostId = p.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9)
GROUP BY 
    pa.PostId, pa.Title, pa.CreationDate, pa.ViewCount, pa.Score, pa.RankScore, pa.MaxViewCount, pa.BadgeStatus
ORDER BY 
    pa.Score DESC,
    pa.CreationDate ASC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;