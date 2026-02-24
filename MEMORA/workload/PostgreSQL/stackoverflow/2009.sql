
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    up.PostId,
    up.Title,
    up.ViewCount,
    up.UpVotes,
    up.DownVotes,
    ub.BadgeCount,
    ub.HighestBadge,
    CASE 
        WHEN up.AcceptedCount > 0 THEN 'Yes'
        ELSE 'No'
    END AS IsAccepted
FROM 
    RankedPosts up
JOIN 
    Users u ON up.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON ub.UserId = u.Id
WHERE 
    up.PostRank <= 3
ORDER BY 
    ub.BadgeCount DESC, up.ViewCount DESC
