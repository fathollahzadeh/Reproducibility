WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.Body, ''), 'No content') AS PostBody 
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserScore AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1
                 WHEN v.VoteTypeId = 3 THEN -1 
                 ELSE 0 END) AS TotalScore
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestEdit,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
ClosedPosts AS (
    SELECT
        p.Id AS ClosedPostId,
        ph.Comment AS CloseReason 
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId 
    WHERE ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.TotalScore,
    phd.LatestEdit,
    phd.EditTypes,
    cp.CloseReason
FROM RankedPosts rp
LEFT JOIN UserScore us ON rp.OwnerUserId = us.UserId
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.ClosedPostId
WHERE 
    rp.Rank = 1 
    AND (rp.Score > 0 OR cp.CloseReason IS NOT NULL) 
    AND EXISTS (SELECT 1 FROM Tags t WHERE t.ExcerptPostId = rp.PostId AND t.Count > 100) 
ORDER BY 
    COALESCE(rp.Score, 0) DESC,
    rp.CreationDate DESC;