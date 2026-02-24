
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName
),
ClosedPostDetails AS (
    SELECT
        ph.PostId,
        MIN(ph.CreationDate) AS FirstCloseDate,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id
    WHERE
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY
        ph.PostId
),
TopClosedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerDisplayName,
        cp.FirstCloseDate,
        cp.CloseCount,
        cp.CloseReasons
    FROM
        RankedPosts rp
    LEFT JOIN ClosedPostDetails cp ON rp.PostId = cp.PostId
    WHERE
        rp.ViewRank <= 5
)
SELECT
    tcp.*,
    CASE
        WHEN tcp.CloseCount IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus,
    COALESCE(ROUND((CAST(tcp.ViewCount AS DECIMAL) / NULLIF(tcp.CloseCount, 0)), 2), 0) AS ViewsPerClose
FROM
    TopClosedPosts tcp
ORDER BY
    tcp.CloseCount DESC NULLS LAST, 
    tcp.ViewCount DESC;
