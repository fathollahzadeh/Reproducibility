
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation, p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT ps.PostId) AS PostsCreated,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpvoteCount) AS TotalUpvotes,
        SUM(ps.DownvoteCount) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ue.UserId,
    ue.PostsCreated,
    ue.TotalViews,
    ue.TotalScore,
    ue.TotalComments,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    u.Reputation AS UserReputation,
    u.CreationDate AS UserCreationDate
FROM 
    UserEngagement ue
JOIN 
    Users u ON ue.UserId = u.Id
ORDER BY 
    ue.TotalViews DESC;
