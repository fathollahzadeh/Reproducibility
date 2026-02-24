
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerDisplayName
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    pa.Title,
    pa.OwnerDisplayName,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.Upvotes,
    pa.Downvotes,
    COALESCE(cpd.CloseCount, 0) AS CloseCount,
    COALESCE(cpd.CloseReasons, 'Not Closed') AS CloseReasons,
    CASE 
        WHEN pa.Score > 10 THEN 'High Score'
        WHEN pa.Score BETWEEN 5 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    PostAnalytics pa
LEFT JOIN 
    ClosedPostDetails cpd ON pa.PostId = cpd.PostId
WHERE 
    pa.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
ORDER BY 
    pa.CreationDate DESC
LIMIT 100;
