
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT DISTINCT 
        ph.PostId,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INTEGER = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(AVG(u.Reputation), 0) AS AvgUserReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        rp.PostId
),
FinalReport AS (
    SELECT 
        pm.PostId,
        rp.Title,
        rp.CreationDate,
        pm.CommentCount,
        pm.TotalBounties,
        pm.AvgUserReputation,
        CASE 
            WHEN cp.CloseReason IS NOT NULL THEN cp.CloseReason
            ELSE 'Not Closed' 
        END AS ClosureStatus,
        CASE 
            WHEN pm.CommentCount IS NULL THEN 'No Comments'
            ELSE 'Has Comments'
        END AS CommentStatus,
        rp.Rank
    FROM 
        PostMetrics pm
    JOIN 
        RankedPosts rp ON pm.PostId = rp.PostId
    LEFT JOIN 
        ClosedPosts cp ON pm.PostId = cp.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.CommentCount,
    f.TotalBounties,
    f.AvgUserReputation,
    f.ClosureStatus,
    f.CommentStatus,
    CASE 
        WHEN f.AvgUserReputation > 1000 THEN 'Elite User Engagement'
        WHEN f.CommentCount > 50 THEN 'Very Active Discussion'
        ELSE 'Standard Post Quality'
    END AS EngagementLevel
FROM 
    FinalReport f
WHERE 
    f.Rank <= 5  
ORDER BY 
    f.CreationDate DESC;
