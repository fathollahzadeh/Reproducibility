WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.AcceptedAnswerId END) AS AcceptedAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
EnhancedPostStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.AcceptedAnswers,
        ps.TotalViews,
        uvs.TotalVotes,
        uvs.Upvotes,
        uvs.Downvotes,
        uvs.AcceptedVotes,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.TotalViews DESC) AS Ranking
    FROM PostStats ps
    JOIN UserVoteStats uvs ON ps.OwnerUserId = uvs.UserId
)
SELECT 
    eps.Title,
    u.DisplayName AS OwnerName,
    eps.CommentCount,
    eps.TotalViews,
    eps.Upvotes,
    eps.Downvotes,
    eps.AcceptedVotes,
    eps.Ranking
FROM EnhancedPostStats eps
JOIN Users u ON eps.OwnerUserId = u.Id
WHERE eps.Ranking <= 5
ORDER BY eps.TotalViews DESC, eps.Upvotes DESC;
