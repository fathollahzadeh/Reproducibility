
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year' 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.CreationDate,
        us.Reputation,
        us.BadgeCount,
        us.TotalBountyAmount,
        us.TotalViews,
        rp.RankByScore,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Tags,
    ps.Score,
    ps.CreationDate,
    ps.Reputation,
    ps.BadgeCount,
    ps.TotalBountyAmount,
    ps.TotalViews,
    ps.RankByScore,
    CASE 
        WHEN ps.RankByScore <= 3 THEN 'Top Performer' 
        ELSE 'Regular Contributor' 
    END AS ContributorType
FROM 
    PostStatistics ps
WHERE 
    ps.CommentCount > 5 
ORDER BY 
    ps.RankByScore, ps.Score DESC;
