
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByOwner
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
), 
FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 12) 
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    fph.EditCount,
    fph.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredPostHistory fph ON rp.Id = fph.PostId
WHERE 
    rp.RankByOwner <= 5 
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
