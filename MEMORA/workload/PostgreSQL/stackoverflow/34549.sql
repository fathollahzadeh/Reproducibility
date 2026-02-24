WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        1 AS Level
    FROM Users
    WHERE Reputation > 0

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        CTE.Level + 1
    FROM Users AS u
    INNER JOIN UserReputationCTE AS CTE ON u.Reputation > CTE.Reputation
    WHERE CTE.Level < 5
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(COALESCE(Length(p.Body), 0)) AS AvgBodyLength
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
), 
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.VoteCount,
        ps.CommentCount,
        ps.AvgBodyLength
    FROM PostStatistics ps
    WHERE ps.VoteCount > 10
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    pp.PostId,
    pp.VoteCount,
    pp.CommentCount,
    pp.AvgBodyLength,
    RANK() OVER (PARTITION BY u.Id ORDER BY pp.VoteCount DESC) AS PostRank,
    CASE 
        WHEN pp.CommentCount > 5 THEN 'Highly Discussed'
        WHEN pp.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Discussed'
        ELSE 'Not Discussed'
    END AS DiscussionLevel,
    SUM(b.Class) OVER (PARTITION BY u.Id) AS TotalBadgeClass 
FROM Users u
JOIN PopularPosts pp ON u.Id = pp.PostId
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE u.Reputation IS NOT NULL
ORDER BY u.Reputation DESC, pp.VoteCount DESC;