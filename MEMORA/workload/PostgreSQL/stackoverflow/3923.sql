
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        rp.*,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC, rp.TotalBounty DESC) AS ScoreRank
    FROM 
        RecentPosts rp
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END, 0)) AS GoldBadges,
        SUM(COALESCE(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END, 0)) AS SilverBadges,
        SUM(COALESCE(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END, 0)) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TotalBounty,
    rp.CommentCount,
    u.DisplayName AS TopUser,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No views'
        WHEN rp.ViewCount > 1000 THEN 'Popular'
        ELSE 'Normal'
    END AS Popularity
FROM 
    RankedPosts rp
JOIN 
    TopUsers u ON rp.OwnerUserId = u.UserId
WHERE 
    rp.ScoreRank <= 10
ORDER BY 
    rp.Score DESC, rp.TotalBounty DESC;
