
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v_up.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v_down.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UpVoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) v_up ON p.Id = v_up.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS DownVoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3
        GROUP BY 
            PostId
    ) v_down ON p.Id = v_down.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UpVoteCount,
    rp.DownVoteCount,
    ub.BadgeNames,
    ub.BadgeCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        ELSE 'Other Post'
    END AS PostStatus,
    CASE 
        WHEN u.Location IS NOT NULL THEN u.Location
        ELSE 'Location not provided'
    END AS UserLocation
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;
