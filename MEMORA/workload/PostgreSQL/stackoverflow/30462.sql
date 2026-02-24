
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalPostViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    up.PostId,
    up.Title,
    up.CreationDate AS PostCreationDate,
    up.Score,
    up.ViewCount,
    up.UpVotes,
    up.DownVotes,
    rph.Comment AS RecentComment,
    rph.CreationDate AS RecentCommentDate,
    CASE 
        WHEN rph.PostHistoryTypeId IS NOT NULL THEN 'Has Recent Activity' 
        ELSE 'No Recent Activity' 
    END AS ActivityStatus,
    COUNT(DISTINCT CASE WHEN up.UserPostRank = 1 THEN up.PostId END) AS RecentTopPosts
FROM 
    UserStats u
LEFT JOIN 
    RankedPosts up ON u.UserId = up.OwnerUserId
LEFT JOIN 
    RecentPostHistory rph ON up.PostId = rph.PostId AND rph.HistoryRank = 1
WHERE 
    (up.Score > 0 OR u.Reputation > 100)
GROUP BY 
    u.DisplayName, u.Reputation, u.GoldBadges, u.SilverBadges, u.BronzeBadges, 
    up.PostId, up.Title, up.CreationDate, up.Score, up.ViewCount, 
    up.UpVotes, up.DownVotes, rph.Comment, rph.CreationDate, rph.PostHistoryTypeId
ORDER BY 
    u.Reputation DESC, up.ViewCount DESC
LIMIT 100;
