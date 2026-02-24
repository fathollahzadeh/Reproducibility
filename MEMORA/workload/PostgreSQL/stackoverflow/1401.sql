WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        COALESCE(rp.UpVotes, 0) AS TotalUpVotes,
        COALESCE(rp.DownVotes, 0) AS TotalDownVotes,
        COALESCE(rp.OwnerRank, 0) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        (SELECT 
            p.OwnerUserId,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
            ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS OwnerRank
        FROM 
            Posts p
        LEFT JOIN 
            Votes v ON p.Id = v.PostId
        GROUP BY 
            p.OwnerUserId) rp ON u.Id = rp.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(u.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN u.HighestBadgeClass IS NULL THEN 'No Badge'
        WHEN u.HighestBadgeClass = 1 THEN 'Gold'
        WHEN u.HighestBadgeClass = 2 THEN 'Silver'
        WHEN u.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'Unknown'
    END AS HighestBadge,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.PostRank
FROM 
    UserStats u
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, u.TotalUpVotes DESC
LIMIT 10;