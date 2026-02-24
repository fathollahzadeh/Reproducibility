
WITH PostSummary AS (
    SELECT 
        p.OwnerUserId,
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(c.Score), 0) AS TotalComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId, pt.Name
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(ps.TotalPosts), 0) AS PostsCount,
        COALESCE(SUM(ps.TotalComments), 0) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        PostSummary ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.PostsCount,
    us.CommentsCount,
    (us.PostsCount + us.CommentsCount) AS TotalInteractions
FROM 
    UserSummary us
ORDER BY 
    TotalInteractions DESC;
