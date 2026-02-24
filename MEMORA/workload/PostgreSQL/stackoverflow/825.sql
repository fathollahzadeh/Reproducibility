
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        u.Id,
        u.DisplayName
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalBounty,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount
FROM 
    UserActivity ua
LEFT JOIN 
    TopPosts tp ON ua.UserId = tp.PostId
WHERE 
    ua.TotalBounty IS NOT NULL
    OR ua.PostCount > 0
ORDER BY 
    ua.TotalBounty DESC, 
    ua.PostCount DESC
LIMIT 10;
