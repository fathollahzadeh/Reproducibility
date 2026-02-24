WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.Reputation
),
HighRepUsers AS (
    SELECT 
        UserId,
        Reputation
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    rp.Title,
    rp.CreationDate,
    pa.ViewCount,
    pa.CommentCount,
    CASE 
        WHEN pa.ViewCount > 100 THEN 'High Views'
        ELSE 'Low Views'
    END AS ViewStatus,
    (SELECT 
        MAX(Score) 
     FROM 
        Posts 
     WHERE 
        OwnerUserId = up.UserId AND 
        PostTypeId = 2
    ) AS MaxAnswerScore
FROM 
    HighRepUsers up
JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    rp.RankByUser <= 3
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate ASC
OFFSET 5 ROWS;
