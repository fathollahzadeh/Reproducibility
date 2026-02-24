
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.Tags, 
        rp.OwnerDisplayName, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.CommentCount, 
        rp.VoteCount, 
        rp.ClosedCount,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC, rp.CreationDate ASC) AS RowNum
    FROM 
        RankedPosts rp
    WHERE 
        rp.ClosedCount > 0 
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.VoteCount
FROM 
    FilteredPosts fp
WHERE 
    fp.RowNum <= 10 
ORDER BY 
    fp.ViewCount DESC, fp.CreationDate ASC;
