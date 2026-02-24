
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankView,
        p.PostTypeId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
AverageScores AS (
    SELECT 
        PostTypeId,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViews
    FROM 
        Posts 
    WHERE 
        CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY COUNT(b.Id) DESC) AS RankBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.RankScore,
    rp.RankView,
    ascores.AvgScore,
    ascores.AvgViews,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalBounty,
    us.RankBadges
FROM 
    RankedPosts rp
INNER JOIN 
    AverageScores ascores ON rp.PostTypeId = ascores.PostTypeId
LEFT JOIN 
    UserStats us ON rp.PostId = (CASE WHEN rp.RankScore <= 10 THEN
        (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
        ELSE NULL END)
WHERE 
    rp.RankScore <= 10 OR rp.RankView <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
