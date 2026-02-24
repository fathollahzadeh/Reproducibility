WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(COUNT(v.Id), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentActivity AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CreationDate,
        ps.VoteCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(ub.BadgeNames, 'No badges') AS UserBadges
    FROM 
        RecursivePostStats ps
    INNER JOIN 
        Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON ub.UserId = ps.OwnerUserId
)
SELECT 
    ra.PostId,
    ra.OwnerUserId,
    ra.CreationDate,
    ra.VoteCount,
    ra.UpVotes,
    ra.DownVotes,
    ra.CommentCount,
    ra.Reputation,
    ra.UserBadgeCount,
    ra.UserBadges,
    CASE 
        WHEN ra.UserBadgeCount > 5 THEN 'High Achiever'
        WHEN ra.UserBadgeCount BETWEEN 3 AND 5 THEN 'Moderate Achiever'
        ELSE 'Novice'
    END AS UserAchievementLevel,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    RecentActivity ra
LEFT JOIN 
    PostHistory ph ON ra.PostId = ph.PostId
GROUP BY 
    ra.PostId, ra.OwnerUserId, ra.CreationDate, ra.VoteCount, ra.UpVotes, ra.DownVotes, 
    ra.CommentCount, ra.Reputation, ra.UserBadgeCount, ra.UserBadges
ORDER BY 
    SUM(ra.UpVotes - ra.DownVotes) DESC,
    ra.CreationDate DESC
LIMIT 100;
