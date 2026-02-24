
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(b.Count, 0)) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS Count 
        FROM Badges 
        GROUP BY UserId
    ) b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.TotalVotes,
    u.BadgeCount,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    p.Rank
FROM UserStatistics u
JOIN PostStatistics p ON u.UserId = p.OwnerUserId
ORDER BY u.Reputation DESC, p.Rank;
