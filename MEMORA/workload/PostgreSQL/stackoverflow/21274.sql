
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown'
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(LENGTH(p.Body)) AS AvgBodyLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
),
BadgesEarned AS (
    SELECT 
        UserId,
        COUNT(Id) AS TotalBadges,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    uReputation.Reputation,
    ps.PostId,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.AvgBodyLength,
    be.TotalBadges,
    be.BadgeNames
FROM 
    Users u
LEFT JOIN 
    UserReputation uReputation ON u.Id = uReputation.UserId
LEFT JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    BadgesEarned be ON u.Id = be.UserId
WHERE 
    uReputation.Reputation IS NOT NULL
    AND (u.CreationDate > CURRENT_DATE - INTERVAL '2 year' OR uReputation.Reputation > 500)
ORDER BY 
    uReputation.Reputation DESC, ps.CommentCount DESC, ps.UpVoteCount DESC
LIMIT 50 OFFSET 50;
