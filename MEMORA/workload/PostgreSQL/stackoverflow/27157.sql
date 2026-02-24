
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(COALESCE(t.TagName, 'N/A')) AS Tags,
        COUNT(c.Id) AS CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        rp.Author
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1) 
        AND rp.Score >= 0
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.Tags,
    fp.CommentCount,
    fp.Author,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    STRING_AGG(DISTINCT bh.Name, ', ') AS BadgeNames
FROM 
    FilteredPosts fp
LEFT JOIN 
    Votes v ON v.PostId = fp.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = fp.Author LIMIT 1)
LEFT JOIN 
    PostHistory ph ON ph.PostId = fp.PostId
LEFT JOIN 
    PostHistoryTypes bh ON bh.Id = ph.PostHistoryTypeId
GROUP BY 
    fp.PostId, fp.Title, fp.ViewCount, fp.Score, fp.Tags, fp.CommentCount, fp.Author
ORDER BY 
    fp.ViewCount DESC, fp.Score DESC;
