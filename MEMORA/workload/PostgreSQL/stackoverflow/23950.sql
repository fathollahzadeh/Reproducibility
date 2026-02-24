
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        AVG(CASE 
                WHEN v.VoteTypeId = 2 THEN 1
                WHEN v.VoteTypeId = 3 THEN -1
                ELSE 0 
            END) AS AvgVoteScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS rn,
        u.LastAccessDate,
        u.Views
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            p.OwnerUserId,
            p.Id,
            COUNT(v.Id) AS VoteCount,
            v.VoteTypeId
        FROM 
            Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
        GROUP BY p.OwnerUserId, p.Id, v.VoteTypeId
    ) v ON u.Id = v.OwnerUserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.LastAccessDate, u.Views
),
HotQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.ViewCount IS NOT NULL
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        RANK() OVER (ORDER BY SUM(COALESCE(c.Score, 0)) DESC) AS CommentRank
    FROM 
        Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(COALESCE(c.Score, 0)) > 0
)
SELECT 
    ur.DisplayName AS UserName,
    ur.Reputation,
    ur.PostCount,
    ur.TotalVotes,
    ur.AvgVoteScore,
    hq.Title AS HotQuestion,
    hq.ViewCount,
    au.TotalCommentScore AS TopCommentScore
FROM 
    UserReputation ur
LEFT JOIN HotQuestions hq ON hq.Rank = 1
JOIN ActiveUsers au ON ur.UserId = au.UserId
WHERE 
    ur.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND ur.PostCount > 3
    AND (ur.LastAccessDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days') OR ur.Views > 100)
ORDER BY 
    ur.Reputation DESC, 
    au.TotalCommentScore DESC
LIMIT 10;
