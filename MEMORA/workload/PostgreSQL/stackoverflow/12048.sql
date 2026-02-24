WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(p.ViewCount) AS TotalViews
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
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalVotes,
    TotalViews,
    RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
    RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank,
    RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank,
    RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
FROM 
    UserActivity
ORDER BY 
    TotalPosts DESC;