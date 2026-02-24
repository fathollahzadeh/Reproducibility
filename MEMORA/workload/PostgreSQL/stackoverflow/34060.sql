
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS PostRank,
        u.Id AS OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
RecentUserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount, 
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount 
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserScore AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    CASE 
        WHEN ub.BadgeCount > 0 THEN 'Gold Badge Holder'
        ELSE 'No Gold Badge'
    END AS BadgeStatus,
    COALESCE(ph.CloseCount, 0) AS TotalCloseActions,
    COALESCE(ph.ReopenCount, 0) AS TotalReopenActions,
    us.TotalScore AS OwnerTotalScore,
    us.PostCount AS OwnerTotalPosts,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentUserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryStats ph ON rp.PostId = ph.PostId
LEFT JOIN 
    UserScore us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
