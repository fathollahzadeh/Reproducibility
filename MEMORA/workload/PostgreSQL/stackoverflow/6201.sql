
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.AnswerCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
),
EngagedUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, COUNT(DISTINCT c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.CreationDate < DATE '2024-10-01' - INTERVAL '90 days'
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT c.Id) > 0
),
HighScoringPosts AS (
    SELECT p.Id, p.Title, p.Score, u.DisplayName, u.Reputation
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.Score > 100
)
SELECT rp.Title AS RecentPostTitle, 
       rp.CreationDate AS RecentPostDate,
       eu.DisplayName AS EngagedUserName, 
       eu.Reputation AS EngagedUserReputation,
       hsp.Title AS HighScoringPostTitle, 
       hsp.Score AS HighScoringPostScore
FROM RecentPosts rp
JOIN EngagedUsers eu ON eu.Id = rp.OwnerUserId
JOIN HighScoringPosts hsp ON hsp.Id = rp.Id
WHERE rp.rn = 1
ORDER BY rp.CreationDate DESC, eu.Reputation DESC
LIMIT 10;
