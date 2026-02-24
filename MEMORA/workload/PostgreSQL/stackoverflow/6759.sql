
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN vt.Name = 'Favorite' THEN 1 ELSE 0 END) AS Favorites
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score
),
UserPostEngagement AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        COUNT(ps.PostId) AS PostCount,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.VoteCount) AS TotalVotes
    FROM UserVoteStats ups
    JOIN Posts pos ON ups.UserId = pos.OwnerUserId
    JOIN PostStats ps ON pos.Id = ps.PostId
    GROUP BY ups.UserId, ups.DisplayName
)
SELECT 
    upe.UserId,
    upe.DisplayName,
    upe.PostCount,
    upe.TotalViews,
    upe.TotalComments,
    upe.TotalVotes,
    u.Reputation
FROM UserPostEngagement upe
JOIN Users u ON upe.UserId = u.Id
WHERE u.Reputation > 1000
ORDER BY upe.TotalVotes DESC, upe.TotalViews DESC
LIMIT 10;
