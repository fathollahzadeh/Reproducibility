
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserId AS CloserUserId,
        COALESCE(u.DisplayName, 'System') AS CloserDisplayName
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.TotalPosts,
        cp.ClosedDate,
        cp.CloserDisplayName,
        CASE 
            WHEN cp.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        COALESCE((SELECT COUNT(*) 
                  FROM Comments c 
                  WHERE c.PostId = rp.PostId), 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
),
FinalOutput AS (
    SELECT 
        pa.*,
        (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
         FROM Tags t 
         JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
         WHERE p.Id = pa.PostId) AS TagList
    FROM 
        PostAnalytics pa
)
SELECT 
    *,
    CASE 
        WHEN PostStatus = 'Closed' AND TotalPosts > 5 THEN 'High Activity Closure' 
        ELSE 'Regular Closure'
    END AS ClosureCategory,
    CASE 
        WHEN CommentCount = 0 THEN 'No Comments Yet'
        ELSE 'Comments Available'
    END AS CommentStatus,
    (SELECT 
         CASE 
             WHEN MAX(v.BountyAmount) > 0 THEN 'Has Bounty'
             ELSE 'No Bounty'
         END
     FROM 
         Votes v 
     WHERE 
         v.PostId = FinalOutput.PostId AND v.VoteTypeId IN (8, 9) 
    ) AS BountyStatus
FROM 
    FinalOutput
WHERE 
    PostStatus = 'Closed' 
ORDER BY 
    Score DESC, ClosedDate DESC
LIMIT 100;
