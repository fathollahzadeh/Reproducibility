
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), 
RecentVoters AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId 
    WHERE 
        u.Reputation > 1000 
), 
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS CloseOpenDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.ViewCount,
    u.DisplayName AS OwnerName,
    us.Reputation AS OwnerReputation,
    us.BadgeCount,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    ph.LatestEditDate,
    ph.CloseOpenDate,
    CASE 
        WHEN ph.CloseOpenDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RecentVoters rv ON rp.PostID = rv.PostId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostID = ph.PostId
WHERE 
    rp.ViewRank <= 3 
ORDER BY 
    rp.ViewCount DESC;
