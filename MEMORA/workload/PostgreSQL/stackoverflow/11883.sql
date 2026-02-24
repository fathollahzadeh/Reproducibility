WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
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
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    COALESCE(ROUND(CAST(ua.TotalUpVotes AS NUMERIC) / NULLIF(ua.TotalPosts, 0), 2), 0) AS UpvotePercentage,
    COALESCE(ROUND(CAST(ua.TotalDownVotes AS NUMERIC) / NULLIF(ua.TotalPosts, 0), 2), 0) AS DownvotePercentage
FROM 
    UserActivity ua
ORDER BY 
    ua.TotalPosts DESC, 
    ua.TotalUpVotes DESC;