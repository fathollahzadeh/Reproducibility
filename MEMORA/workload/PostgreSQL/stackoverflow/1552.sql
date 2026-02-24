
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT 
    ua.DisplayName,
    ua.TotalScore,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalVotes,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.PostType,
    CASE 
        WHEN ps.CreationDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days') THEN 'Inactive'
        ELSE 'Active'
    END AS UserStatus,
    (SELECT 
         COUNT(*) 
     FROM 
         PostHistory ph 
     WHERE 
         ph.PostId = ps.Id AND 
         ph.PostHistoryTypeId IN (10, 11, 12)) AS ClosureHistory
FROM 
    UserActivity ua
LEFT JOIN 
    PostStatistics ps ON ua.UserId = ps.OwnerUserId
WHERE 
    ua.TotalScore > 50
ORDER BY 
    ua.TotalScore DESC, 
    ps.CreationDate DESC
LIMIT 10;
