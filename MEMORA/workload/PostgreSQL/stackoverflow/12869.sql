
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (8, 9) THEN 1 ELSE 0 END) AS Bounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),

PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        pt.Name AS PostType,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
)

SELECT 
    ua.UserId,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalComments,
    ua.Upvotes,
    ua.Downvotes,
    ua.Bounties,
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.OwnerDisplayName,
    pm.PostType
FROM 
    UserActivity ua
LEFT JOIN 
    PostMetrics pm ON ua.UserId = pm.OwnerUserId
ORDER BY 
    ua.Reputation DESC, ua.TotalPosts DESC, pm.Score DESC;
