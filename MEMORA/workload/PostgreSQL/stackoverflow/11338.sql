WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.CreationDate, p.Title, p.Score, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.AnswerCount,
    ua.UserId,
    ua.Reputation,
    ua.PostsCreated,
    ua.TotalViews,
    ua.TotalScore
FROM 
    PostDetails pd
JOIN 
    UserActivity ua ON pd.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;