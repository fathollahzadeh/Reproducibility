
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RN,
        COALESCE(u.DisplayName, '[Deleted User]') AS OwnerName,
        CASE 
            WHEN p.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR' THEN 'Legacy'
            ELSE 'Recent'
        END AS PostAge
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        oc.CommentCount,
        cp.LastClosedDate,
        cp.CloseReasons,
        p.PostAge
    FROM 
        RankedPosts p
    LEFT JOIN 
        PostComments oc ON p.PostId = oc.PostId
    LEFT JOIN 
        ClosedPosts cp ON p.PostId = cp.PostId
    WHERE 
        p.RN <= 5 
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.Score,
    COALESCE(fr.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN fr.CloseReasons IS NOT NULL THEN 'Closed with reasons: ' || fr.CloseReasons 
        ELSE 'Open' 
    END AS PostStatus,
    fr.PostAge
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, 
    fr.ViewCount DESC;
