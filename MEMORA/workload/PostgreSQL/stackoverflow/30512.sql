WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON u.Reputation > ur.Reputation AND ur.Level < 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        MAX(p.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    WHERE Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY UserId
),
FinalResult AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COALESCE(bc.BadgeCount, 0) AS RecentBadgeCount,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ps.LastActivity DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        BadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.CommentCount  
)
SELECT 
    fr.DisplayName,
    fr.Reputation,
    fr.RecentBadgeCount,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    CASE 
        WHEN fr.Reputation > 5000 THEN 'Highly Reputable'
        WHEN fr.Reputation BETWEEN 2000 AND 5000 THEN 'Moderately Reputable'
        ELSE 'New Contributor'
    END AS ReputationCategory
FROM 
    FinalResult fr
WHERE 
    fr.ActivityRank = 1
ORDER BY 
    fr.Reputation DESC
LIMIT 50;