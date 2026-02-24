
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    t.Id,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.OwnerDisplayName,
    COALESCE(t.CommentCount, 0) AS NonNullCommentCount,
    CASE 
        WHEN t.Score IS NULL THEN 'No Score' 
        WHEN t.Score > 100 THEN 'Hot Post' 
        ELSE 'Regular Post' 
    END AS PostStatus,
    STRING_AGG(CONCAT('User: ', u.DisplayName, ' voted ', CASE WHEN v.VoteTypeId = 2 THEN 'up' ELSE 'down' END), '; ') AS VoterDetails
FROM 
    TopPosts t
LEFT JOIN 
    Votes v ON v.PostId = t.Id
LEFT JOIN 
    Users u ON v.UserId = u.Id
GROUP BY 
    t.Id, t.Title, t.CreationDate, t.Score, t.ViewCount, t.OwnerDisplayName, t.CommentCount
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
