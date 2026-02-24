WITH PostStatistics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUsers,
        COUNT(DISTINCT Id) FILTER (WHERE ParentId IS NOT NULL) AS TotalAnswers,
        COUNT(DISTINCT Id) FILTER (WHERE ParentId IS NULL) AS TotalQuestions
    FROM 
        Posts
),
UserStatistics AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
),
CommentStatistics AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AvgCommentScore
    FROM 
        Comments
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    ORDER BY 
        p.CreationDate DESC
    LIMIT 10
)
SELECT 
    ps.TotalPosts,
    ps.TotalUsers,
    ps.TotalAnswers,
    ps.TotalQuestions,
    us.TotalUsers AS UniqueUsers,
    us.AvgReputation,
    cs.TotalComments,
    cs.AvgCommentScore,
    rp.Id AS RecentPostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.OwnerDisplayName AS RecentPostOwner
FROM 
    PostStatistics ps,
    UserStatistics us,
    CommentStatistics cs,
    RecentPosts rp;