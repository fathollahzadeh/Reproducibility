
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.Score,
    COALESCE(cpr.CloseReasons, ARRAY[]::text[]) AS CloseReasons,
    rp.CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostReasons cpr ON rp.Id = cpr.PostId
WHERE 
    rp.rn = 1 OR rp.Score > 50
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 10;
