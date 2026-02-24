WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(p.Body, 'No content provided') AS SafeBody
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= COALESCE((SELECT MIN(CreationDate) FROM Posts WHERE PostTypeId = 1), '2000-01-01')
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgePoints,
        COUNT(DISTINCT p.Id) AS QuestionsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment = CAST(crt.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    pu.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(cp.CloseReasons, 'No close reasons') AS FinalCloseReasons,
    t.TotalBadgePoints,
    t.QuestionsCount,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No views registered' 
        ELSE CASE 
            WHEN rp.ViewCount > 1000 THEN 'Highly popular'
            WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately popular'
            ELSE 'Less popular'
        END
    END AS PopularityStatus
FROM 
    RankedPosts rp
JOIN 
    Users pu ON rp.OwnerUserId = pu.Id
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
INNER JOIN 
    TopUsers t ON pu.Id = t.UserId
WHERE 
    rp.rn = 1 
    AND (rp.Score IS NULL OR rp.Score > 10)
ORDER BY 
    t.TotalBadgePoints DESC, rp.CreationDate DESC
LIMIT 100 OFFSET 0;
