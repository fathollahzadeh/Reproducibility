WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
TopPosts AS (
    SELECT 
        Rp.Id, 
        Rp.Title, 
        Rp.OwnerDisplayName, 
        Rp.CreationDate, 
        Rp.Score, 
        Rp.ViewCount
    FROM 
        RankedPosts Rp
    WHERE 
        Rank <= 5
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    Tp.Title,
    Tp.OwnerDisplayName,
    Tp.Score,
    Tp.ViewCount,
    UBC.BadgeCount
FROM 
    TopPosts Tp
LEFT JOIN 
    UserBadgeCounts UBC ON Tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = UBC.UserId)
ORDER BY 
    Tp.Score DESC, Tp.ViewCount DESC;
