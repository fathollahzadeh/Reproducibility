
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS OwnerRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, u.DisplayName
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId IN (2, 4)) AS TotalVotes,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerRank <= 10
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.ViewCount,
    ps.CommentCount,
    ps.TotalVotes,
    ps.CloseCount,
    COALESCE(ROUND(CAST(ps.TotalVotes AS numeric) / NULLIF(ps.ViewCount, 0) * 100, 2), 0) AS VotePercentage,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostStatistics ps
ORDER BY 
    ps.ViewCount DESC, ps.CommentCount DESC;
