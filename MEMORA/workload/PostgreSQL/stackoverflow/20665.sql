
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM
        Posts p
    LEFT JOIN
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND (p.Title IS NOT NULL OR p.Body IS NOT NULL)
    GROUP BY
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, U.DisplayName
), ClosedPosts AS (
    SELECT
        p.Id,
        PH.UserDisplayName,
        PH.CreationDate AS ClosedDate,
        PH.Comment AS CloseReason
    FROM
        Posts p
    JOIN
        PostHistory PH ON p.Id = PH.PostId
    WHERE
        PH.PostHistoryTypeId = 10  
)
SELECT
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.ScoreRank,
    cp.ClosedDate,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason
FROM
    RankedPosts rp
LEFT JOIN
    ClosedPosts cp ON rp.PostId = cp.Id
WHERE
    rp.ScoreRank <= 10
ORDER BY
    rp.Score DESC, cp.ClosedDate DESC
LIMIT 20;
