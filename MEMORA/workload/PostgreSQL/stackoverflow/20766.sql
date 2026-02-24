
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR' 
        AND p.Score IS NOT NULL
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS UserComments
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 MONTHS'
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate, pht.Name
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::text::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Reputation,
        rp.Rank,
        rp.CommentCount,
        COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReasons,
        COALESCE(pd.UserComments, 'No Updates') AS UserComments,
        pd.HistoryCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        PostHistoryDetails pd ON rp.PostId = pd.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    Reputation,
    Rank,
    CommentCount,
    CloseReasons,
    UserComments,
    HistoryCount
FROM 
    FinalReport
WHERE 
    (Reputation <= 50 AND Rank <= 5) 
    OR (CloseReasons != 'Not Closed' AND HistoryCount > 1)
ORDER BY 
    Score DESC NULLS LAST,
    CreationDate DESC;
