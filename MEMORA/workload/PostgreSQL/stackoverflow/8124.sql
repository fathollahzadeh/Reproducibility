
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPosts,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    up.DisplayName AS UserName,
    up.Reputation,
    COUNT(rp.PostId) AS TotalPosts,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.AnswerCount) AS TotalAnswers,
    AVG(rp.Score) AS AverageScore,
    AVG(rp.ViewCount) AS AverageViews
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation
HAVING 
    COUNT(rp.PostId) > 5
ORDER BY 
    AverageScore DESC, TotalPosts DESC
LIMIT 10;
