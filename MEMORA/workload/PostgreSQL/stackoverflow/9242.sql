
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    u.Reputation AS OwnerReputation,
    b.Name AS BadgeName,
    bp.BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    (SELECT 
         UserId, 
         Name,
         COUNT(*) AS BadgeCount
     FROM 
         Badges 
     GROUP BY 
         UserId, Name) bp ON u.Id = bp.UserId
LEFT JOIN 
    Badges b ON bp.UserId = b.UserId AND bp.Name = b.Name
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
