
WITH UserReputation AS (
    SELECT
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation < 100 THEN 'Low'
            WHEN Reputation < 1000 THEN 'Medium'
            ELSE 'High'
        END AS ReputationCategory
    FROM Users
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(a.Score, 0) AS AcceptedAnswerScore,
        p.Score AS PostScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.Score, a.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.ReputationCategory,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes,
        DENSE_RANK() OVER (PARTITION BY ur.ReputationCategory ORDER BY SUM(ps.UpVotes) DESC) AS Rank
    FROM UserReputation ur
    JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    JOIN Users u ON ps.OwnerUserId = u.Id
    GROUP BY u.Id, u.DisplayName, ur.ReputationCategory
),
PostAnalytics AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PostScore,
        ps.CommentCount,
        u.DisplayName,
        COALESCE(tu.Rank, 0) AS UserRank,
        (ps.UpVotes - ps.DownVotes) AS NetVotes,
        ROUND((COALESCE(ps.CommentCount, 0) + ps.UpVotes - ps.DownVotes) * 1.0 / NULLIF(ps.CommentCount + 1, 0), 2) AS EngagementScore
    FROM PostStats ps
    LEFT JOIN Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN TopUsers tu ON u.Id = tu.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.PostScore,
    pa.CommentCount,
    pa.DisplayName,
    pa.UserRank,
    pa.NetVotes,
    pa.EngagementScore
FROM PostAnalytics pa
WHERE pa.UserRank <= 5
ORDER BY pa.PostScore DESC, pa.NetVotes DESC;
