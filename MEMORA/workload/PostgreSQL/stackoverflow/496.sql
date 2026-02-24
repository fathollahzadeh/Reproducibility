WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
RecentActivities AS (
    SELECT 
        Ph.PostId,
        Ph.UserId,
        Ph.CreationDate,
        P.Title AS PostTitle,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory Ph
    JOIN 
        Posts P ON Ph.PostId = P.Id
    WHERE 
        Ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 DAYS'
),
CombinedResults AS (
    SELECT 
        rp.Title AS PostTitle,
        rp.OwnerDisplayName,
        ra.UserId,
        ra.CreationDate as LastActivityDate,
        COALESCE(ra.Score, 0) AS ActivityScore
    FROM 
        RankedPosts rp
    FULL OUTER JOIN 
        RecentActivities ra ON rp.Id = ra.PostId
    WHERE 
        (rp.Rank = 1 OR ra.ActivityRank = 1)
)
SELECT 
    PostTitle,
    OwnerDisplayName,
    LastActivityDate,
    ActivityScore,
    CASE 
        WHEN ActivityScore > 0 THEN 'Active'
        WHEN LastActivityDate IS NULL THEN 'No Activity'
        ELSE 'Inactive' 
    END AS PostStatus
FROM 
    CombinedResults
WHERE 
    OwnerDisplayName IS NOT NULL
    AND (ActivityScore > 0 OR LastActivityDate IS NOT NULL)
ORDER BY 
    ActivityScore DESC, LastActivityDate DESC
LIMIT 50;