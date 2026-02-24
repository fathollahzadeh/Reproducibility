
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        STRING_AGG(ph.Comment, '; ') AS EditComments,
        MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS LastActionDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 24)
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.Comment
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.DisplayName AS UserOwner,
    us.BadgeCount,
    us.TotalBounty,
    phd.EditComments,
    phd.LastActionDate,
    CASE 
        WHEN phd.CloseReason IS NOT NULL THEN 'Post is Closed'
        ELSE 'Post is Active'
    END AS PostStatus,
    CASE 
        WHEN us.TotalBounty > 500 THEN 'High Bounty Holder'
        WHEN us.TotalBounty > 200 THEN 'Medium Bounty Holder'
        ELSE 'Low Bounty Holder'
    END AS BountyCategory
FROM 
    RankedPosts rp 
LEFT JOIN 
    UserStats us ON rp.PostId = us.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    (rp.RankByScore <= 5 OR rp.RankByDate <= 10)
    AND (us.BadgeCount > 0 OR us.TotalBounty > 0)
    AND (phd.LastActionDate IS NULL OR phd.LastActionDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
