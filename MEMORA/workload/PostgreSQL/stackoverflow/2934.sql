
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'High Traffic'
            WHEN rp.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Traffic'
            ELSE 'Low Traffic'
        END AS TrafficType
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN <= 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.OwnerName,
    fp.CommentCount,
    fp.AvgBounty,
    fp.TrafficType,
    COALESCE(ph.Comment, 'No previous edits') AS PreviousEditComment,
    ph.CreationDate AS EditDate
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (24, 50, 12) 
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
