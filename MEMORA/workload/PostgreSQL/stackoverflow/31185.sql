
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        0 AS Depth
    FROM Users u
    WHERE u.Reputation IS NOT NULL
  
    UNION ALL
  
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Depth + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON u.Id = ur.UserId
    WHERE ur.Depth < 5 
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        ps.PostId,
        ps.CommentCount,
        ps.VoteCount,
        ps.HasAcceptedAnswer,
        ps.TotalScore
    FROM Users u
    JOIN UserReputationCTE ur ON u.Id = ur.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    COUNT(ups.PostId) AS NumberOfPosts,
    SUM(COALESCE(ups.CommentCount, 0)) AS TotalComments,
    SUM(COALESCE(ups.VoteCount, 0)) AS TotalVotes,
    SUM(COALESCE(ups.TotalScore, 0)) AS TotalScore,
    AVG(CASE WHEN ups.HasAcceptedAnswer = 1 THEN 1 ELSE NULL END) AS AcceptedAnswerRate
FROM UserPostStats ups
GROUP BY ups.UserId, ups.DisplayName, ups.Reputation
HAVING SUM(ups.TotalScore) > 0 
ORDER BY TotalScore DESC
LIMIT 10;
