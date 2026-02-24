
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    us.UserId, 
    us.DisplayName, 
    us.TotalScore, 
    us.PostCount, 
    us.BadgeCount, 
    us.UpVotes, 
    us.DownVotes,
    u.Reputation,
    u.CreationDate
FROM UserStatistics us
JOIN Users u ON us.UserId = u.Id
ORDER BY us.TotalScore DESC
LIMIT 100;
