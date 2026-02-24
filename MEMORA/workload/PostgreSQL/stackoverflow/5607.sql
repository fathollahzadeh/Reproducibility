
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN COUNT(DISTINCT a.Id)
            ELSE 0 
        END AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    GROUP BY 
        p.Id, p.Title, p.OwnerDisplayName, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.CreationDate,
    r.Score AS PostScore,
    r.ViewCount,
    r.CommentCount,
    r.AnswerCount,
    u.UserId,
    u.DisplayName AS UserName,
    u.TotalScore,
    u.PostCount
FROM 
    RankedPosts r
JOIN 
    TopUsers u ON r.OwnerUserId = u.UserId
WHERE 
    r.Rank <= 5
ORDER BY 
    u.TotalScore DESC, r.Score DESC;
