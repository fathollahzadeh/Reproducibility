
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
), 
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerName,
        tp.CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END), 0) AS Favorites
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerName, tp.CommentCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN ps.UpVotes + ps.DownVotes > 0 THEN ROUND((CAST(ps.UpVotes AS numeric) / (ps.UpVotes + ps.DownVotes)) * 100, 2)
        ELSE NULL 
    END AS VotePercentage,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    PostStats ps
LEFT JOIN 
    (SELECT UserId, Name FROM Badges WHERE Class = 1) b ON ps.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    ps.CommentCount > 10
ORDER BY 
    VotePercentage DESC 
LIMIT 50;
