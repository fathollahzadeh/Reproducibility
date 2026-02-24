WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR' 
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerUserId, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
UserScores AS (
    SELECT 
        u.Id AS UserId, 
        SUM(p.Score) AS TotalScore, 
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Score,
    tp.ViewCount, 
    tp.OwnerDisplayName,
    us.TotalScore AS UserTotalScore,
    us.TotalPosts AS UserTotalPosts
FROM 
    TopPosts tp
JOIN 
    UserScores us ON tp.OwnerUserId = us.UserId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;