
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(COUNT(c.Id) FILTER (WHERE c.Score > 0), 0) AS PositiveCommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.Score, p.ViewCount, p.CreationDate, U.DisplayName
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

HighRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        CASE 
            WHEN phs.HistoryCount IS NULL THEN 'No History'
            WHEN phs.LastCloseDate IS NOT NULL AND phs.LastReopenDate IS NOT NULL 
                AND phs.LastCloseDate > phs.LastReopenDate THEN 'Currently Closed'
            WHEN phs.LastCloseDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        rp.PositiveCommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    WHERE 
        rp.rn = 1  
)

SELECT 
    hp.PostId,
    hp.Title,
    hp.OwnerDisplayName,
    hp.PostStatus,
    hp.PositiveCommentCount,
    (SELECT COUNT(DISTINCT v.Id) 
     FROM Votes v 
     WHERE v.PostId = hp.PostId AND v.VoteTypeId IN (2, 9)) AS TotalUpvotes
FROM 
    HighRankedPosts hp
WHERE 
    hp.PostStatus != 'No History' 
ORDER BY 
    hp.PostStatus DESC, 
    hp.PositiveCommentCount DESC;
