
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(Id) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(Id) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
)
SELECT 
    u.DisplayName,
    SUM(uv.VoteCount) AS TotalVotes,
    SUM(uv.Upvotes) AS TotalUpvotes,
    SUM(uv.Downvotes) AS TotalDownvotes,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.ViewCount) AS TotalViews,
    SUM(ps.AnswerCount) AS TotalAnswers,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.BadgeCount) AS TotalBadges
FROM 
    UserVoteCounts uv
JOIN 
    Users u ON uv.UserId = u.Id
JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalVotes DESC
LIMIT 10;
