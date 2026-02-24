
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND
        rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) AND
        EXISTS (
            SELECT 1 
            FROM Comments c 
            WHERE c.PostId = rp.PostId 
            AND c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
        )
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Rank,
    CASE 
        WHEN fp.ViewCount IS NULL THEN 'No views recorded'
        ELSE CAST(fp.ViewCount AS VARCHAR)
    END AS ViewCountDisplay,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT 
        COALESCE(SUM(v.BountyAmount), 0)
        FROM Votes v 
        WHERE v.PostId = fp.PostId AND v.VoteTypeId IN (8, 9)
    ) AS TotalBountyAmount,
    fp.Tags
FROM 
    FilteredPosts fp
LEFT OUTER JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11)) > 1
ORDER BY 
    fp.Rank;
