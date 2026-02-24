
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(ap.PostId) AS TotalPosts,
        SUM(COALESCE(a.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(ap.UpVotes, 0) - COALESCE(ap.DownVotes, 0)) AS Score,
        SUM(COALESCE(a.AnswerCount, 0)) AS AcceptedAnswers
    FROM Users u
    LEFT JOIN ActivePosts ap ON u.Id = ap.OwnerUserId
    LEFT JOIN (SELECT 
                    Posts.OwnerUserId, 
                    COUNT(*) AS AnswerCount 
                FROM Posts 
                WHERE PostTypeId = 2 
                GROUP BY Posts.OwnerUserId) a ON u.Id = a.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ups.TotalPosts,
    ups.TotalAnswers,
    ups.Score,
    ups.AcceptedAnswers,
    COALESCE(ur.ReputationRank, 0) AS ReputationRank,
    CASE 
        WHEN ups.Score > 100 THEN 'High Score'
        WHEN ups.Score BETWEEN 51 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM UserReputation ur
FULL OUTER JOIN UserPostStats ups ON ur.UserId = ups.UserId
WHERE (ups.TotalPosts IS NULL OR ups.TotalPosts > 5) 
    AND (ur.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' OR ur.ReputationRank IS NOT NULL)
ORDER BY ups.Score DESC NULLS LAST;
