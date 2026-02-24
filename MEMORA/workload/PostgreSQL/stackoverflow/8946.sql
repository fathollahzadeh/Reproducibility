WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.PostTypeId IN (1, 2) 
),
TopRankedPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    trp.PostID,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE 
        WHEN v.VoteTypeId = 2 THEN 1 
        ELSE 0 
     END) AS TotalUpVotes,
    SUM(CASE 
        WHEN v.VoteTypeId = 3 THEN 1 
        ELSE 0 
     END) AS TotalDownVotes
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Comments c ON trp.PostID = c.PostId
LEFT JOIN 
    Votes v ON trp.PostID = v.PostId
GROUP BY 
    trp.PostID, 
    trp.Title, 
    trp.CreationDate, 
    trp.Score, 
    trp.ViewCount, 
    trp.OwnerDisplayName
ORDER BY 
    trp.Score DESC, 
    trp.ViewCount DESC;