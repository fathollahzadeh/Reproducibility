
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    t.DisplayName,
    t.QuestionCount,
    t.TotalScore,
    t.AvgViewCount,
    COALESCE(cr.CloseReasonNames, 'No Closures') AS CloseReasons,
    COUNT(pc.RelatedPostId) AS RelatedPostLinks
FROM 
    TopUsers t
LEFT JOIN 
    CloseReasons cr ON t.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = cr.PostId
    )
LEFT JOIN 
    PostLinks pc ON pc.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = t.UserId
    )
WHERE 
    t.QuestionCount > 5
GROUP BY 
    t.UserId, t.DisplayName, t.QuestionCount, t.TotalScore, t.AvgViewCount, cr.CloseReasonNames
ORDER BY 
    t.TotalScore DESC, t.QuestionCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
