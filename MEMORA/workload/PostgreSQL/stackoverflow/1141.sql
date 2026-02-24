WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus,
        
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        
        (
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3) 
        ) AS VoteCount
    FROM 
        Posts p
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalScore,
    ua.AvgViewCount,
    ps.PostId,
    ps.Title,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.AnswerStatus,
    ps.RecentPostRank,
    ps.VoteCount
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.UserId = ps.PostId
WHERE 
    ua.PostCount > 5
    AND ps.AnswerStatus = 'Accepted'
ORDER BY 
    ua.TotalScore DESC, 
    ps.RecentPostRank
LIMIT 100
OFFSET 0;