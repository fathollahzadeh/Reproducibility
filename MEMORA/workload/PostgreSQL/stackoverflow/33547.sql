
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerUserId,
        Rank,
        CommentCount,
        TotalBounty
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
)
SELECT 
    tp.PostId,
    tp.Title,
    U.DisplayName AS OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.TotalBounty,
    COALESCE(ba.Name, 'No Badge') AS RecentBadge,
    COUNT(ph.Id) AS EditHistoryCount
FROM 
    TopPosts tp
LEFT JOIN 
    Users U ON tp.OwnerUserId = U.Id
LEFT JOIN 
    Badges ba ON U.Id = ba.UserId AND ba.Date = (
        SELECT MAX(Date) FROM Badges WHERE UserId = U.Id
    )
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    U.Reputation > 1000 
GROUP BY 
    tp.PostId, tp.Title, U.DisplayName, tp.Score, tp.ViewCount, tp.CommentCount, tp.TotalBounty, ba.Name
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
