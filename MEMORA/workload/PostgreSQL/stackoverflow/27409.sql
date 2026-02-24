
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class AS BadgeClass,
        b.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Class, b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(p.CreationDate) AS LastActivity,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
BadgedUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COUNT(DISTINCT ub.BadgeName) AS TotalBadges,
        MAX(ub.BadgeClass) AS HighestBadgeClass
    FROM 
        UserBadges ub
    WHERE 
        ub.BadgeRank = 1
    GROUP BY 
        ub.UserId, ub.DisplayName
)
SELECT 
    u.DisplayName,
    bu.TotalBadges,
    bu.HighestBadgeClass,
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.LastActivity
FROM 
    BadgedUsers bu
JOIN 
    Users u ON bu.UserId = u.Id
JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
WHERE 
    bu.TotalBadges > 0
ORDER BY 
    bu.TotalBadges DESC, ps.LastActivity DESC
LIMIT 10;
