
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score IS NOT NULL AND 
        p.Score > 0
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
), 
CloseReasonStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseVoteCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id 
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    us.QuestionCount,
    us.TotalViewCount,
    us.AverageScore,
    COALESCE(crs.CloseVoteCount, 0) AS CloseVoteCount,
    COALESCE(crs.CloseReasons, 'None') AS CloseReasons,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViewCount
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
LEFT JOIN 
    CloseReasonStats crs ON us.UserId = crs.UserId
JOIN 
    Users u ON us.UserId = u.Id
WHERE 
    us.QuestionCount > 5 AND  
    us.AverageScore IS NOT NULL AND
    (us.TotalViewCount >= 100 OR us.AverageScore >= 10)
ORDER BY 
    us.AverageScore DESC, us.TotalViewCount DESC;
