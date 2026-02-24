
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(c.Score) AS TotalCommentScore,
        AVG(p.Score) AS AveragePostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.CreationDate,
        p.LastActivityDate,
        pt.Name AS PostType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
),
UserPostStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        ps.PostId,
        ps.Title,
        ps.PostType,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.FavoriteCount
    FROM 
        UserActivity u
    JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    JOIN 
        PostStatistics ps ON p.Id = ps.PostId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalCommentScore,
    ua.AveragePostScore,
    ups.Title AS PostTitle,
    ups.PostType,
    ups.ViewCount,
    ups.AnswerCount,
    ups.CommentCount,
    ups.FavoriteCount
FROM 
    UserActivity ua
LEFT JOIN 
    UserPostStats ups ON ua.UserId = ups.UserId
ORDER BY 
    ua.TotalPosts DESC;
