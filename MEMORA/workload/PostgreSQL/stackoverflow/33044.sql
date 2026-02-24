
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVitals AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        ub.BadgeCount,
        CASE 
            WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
            WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
            WHEN ub.HighestBadgeClass = 3 THEN 'Bronze'
            ELSE 'No Badges'
        END AS BadgeLevel,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
),
UserActivity AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END), 0) AS Favorites
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ua.DisplayName,
    pv.Title,
    pv.CreationDate,
    pv.Score,
    pv.ViewCount,
    pv.CommentCount,
    pv.BadgeLevel,
    ua.UpVotes,
    ua.DownVotes,
    ua.Favorites
FROM 
    PostVitals pv
JOIN 
    UserActivity ua ON pv.OwnerUserId = ua.Id
WHERE 
    pv.Score > 0
    AND (pv.BadgeLevel = 'Gold' OR pv.BadgeLevel = 'Silver')
ORDER BY 
    pv.Score DESC,
    pv.ViewCount DESC
LIMIT 50;
