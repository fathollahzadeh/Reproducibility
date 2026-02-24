WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.CommentCount) AS AvgCommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
UserVoteStatistics AS (
    SELECT 
        v.UserId AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes v
    GROUP BY v.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.AvgViewCount,
    ups.AvgCommentCount,
    uvs.TotalVotes,
    uvs.Upvotes,
    uvs.Downvotes
FROM UserPostStatistics ups
LEFT JOIN UserVoteStatistics uvs ON ups.UserId = uvs.UserId
ORDER BY ups.TotalPosts DESC, ups.TotalScore DESC;