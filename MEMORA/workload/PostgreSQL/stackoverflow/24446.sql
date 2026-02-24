
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS PostCount,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        AVG(v.BountyAmount) AS AvgBounty,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        vt.Name AS VoteTypeName
    FROM 
        PostHistory ph
    JOIN 
        VoteTypes vt ON ph.PostHistoryTypeId = 10
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.AvgBounty,
    us.VoteCount,
    rp.PostId,
    rp.Title,
    rp.Rank,
    rp.PostCount,
    rcp.CreationDate AS RecentCloseDate,
    rcp.Comment,
    rcp.VoteTypeName,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.PostCount > 5 THEN 'Frequent Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentClosedPosts rcp ON rp.PostId = rcp.PostId
WHERE 
    us.VoteCount > 0
ORDER BY 
    us.VoteCount DESC, 
    us.DisplayName ASC, 
    rp.Rank ASC
LIMIT 50;
