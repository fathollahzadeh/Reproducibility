
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.VoteCount,
        rp.OwnerRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerRank <= 3  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.VoteCount,
    COUNT(c.Id) AS CommentCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)  
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.OwnerDisplayName, fp.VoteCount
ORDER BY 
    fp.Score DESC, fp.VoteCount DESC;
