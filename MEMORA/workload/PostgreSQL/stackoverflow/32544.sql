
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(rc.CommentCount, 0) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) rc ON rp.PostId = rc.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId IN (9, 8) 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rc.CommentCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    INNER JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed' ELSE 'Edited' END, ', ') AS EditTypes
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserDisplayName, ph.CreationDate
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.CommentCount,
    p.TotalBountyAmount,
    u.DisplayName AS TopUser,
    u.TotalScore,
    phs.EditCount,
    phs.EditTypes
FROM 
    PostWithComments p
JOIN 
    TopUsers u ON p.Score = u.TotalScore
LEFT JOIN 
    PostHistorySummary phs ON p.PostId = phs.PostId
WHERE 
    p.Score > 100 AND 
    p.CommentCount > 5 AND 
    u.TotalScore IS NOT NULL
ORDER BY 
    p.Score DESC, 
    p.CommentCount DESC;
