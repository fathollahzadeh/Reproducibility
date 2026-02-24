WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(c.UserId, -1) AS CommentUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score > 0
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), PopularPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        COUNT(c.Id) AS CommentCount, 
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.Rank <= 3
    GROUP BY 
        rp.PostId, rp.Title
), UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pp.PostId, 
    pp.Title, 
    pp.CommentCount, 
    us.DisplayName AS TopUser, 
    us.GoldBadges
FROM 
    PopularPosts pp
JOIN 
    UserStats us ON pp.CommentCount = (
        SELECT MAX(CommentCount) 
        FROM PopularPosts 
    )
WHERE 
    pp.CommentCount > 5
ORDER BY 
    pp.CommentCount DESC
LIMIT 10;