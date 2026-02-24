WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(c.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(v.VoteCount), 0) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalComments,
    TotalVotes
FROM UserPostStats
ORDER BY PostCount DESC, TotalVotes DESC
LIMIT 100;