WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
        p.AnswerCount, p.CommentCount, p.FavoriteCount
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalComments,
    ue.TotalVotes,
    ue.TotalViews,
    ue.TotalScore,
    ue.TotalBadges,
    pe.PostId,
    pe.Title AS PostTitle,
    pe.CreationDate AS PostCreationDate,
    pe.ViewCount AS PostViewCount,
    pe.Score AS PostScore,
    pe.AnswerCount,
    pe.CommentCount AS PostCommentCount,
    pe.FavoriteCount AS PostFavoriteCount,
    pe.TotalComments AS PostTotalComments,
    pe.TotalVotes AS PostTotalVotes
FROM 
    UserEngagement ue
JOIN 
    PostEngagement pe ON ue.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pe.PostId)
ORDER BY 
    ue.TotalScore DESC, ue.TotalPosts DESC;