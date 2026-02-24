
WITH UserVotes AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(b.FavoriteCount, 0) AS FavoriteCount
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId AS PostId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS FavoriteCount
        FROM Votes 
        WHERE VoteTypeId = 5
        GROUP BY PostId
    ) b ON p.Id = b.PostId
),
UserEngagement AS (
    SELECT 
        uv.UserId, 
        uv.DisplayName, 
        SUM(pe.ViewCount) AS TotalViews,
        SUM(pe.CommentCount) AS TotalComments,
        SUM(pe.AnswerCount) AS TotalAnswers,
        SUM(pe.FavoriteCount) AS TotalFavorites
    FROM UserVotes uv
    JOIN Posts p ON uv.UserId = p.OwnerUserId
    JOIN PostEngagement pe ON p.Id = pe.PostId
    GROUP BY uv.UserId, uv.DisplayName
)
SELECT 
    ue.UserId, 
    ue.DisplayName, 
    uv.TotalVotes, 
    uv.UpVotes, 
    uv.DownVotes, 
    ue.TotalViews, 
    ue.TotalComments, 
    ue.TotalAnswers, 
    ue.TotalFavorites
FROM UserEngagement ue
JOIN UserVotes uv ON ue.UserId = uv.UserId
ORDER BY ue.TotalViews DESC, uv.TotalVotes DESC
LIMIT 10;
