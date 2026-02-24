
WITH RecursiveBadgeCounts AS (
    
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    GROUP BY 
        b.UserId
),
HighReputationUsers AS (
    SELECT 
        UserId,
        BadgeCount 
    FROM 
        RecursiveBadgeCounts 
    WHERE 
        MaxReputation > 1000
),
PostStats AS (
    
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CloseReasons AS (
    
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UserPostStats AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AverageViewCount, 0) AS AverageViewCount,
        COALESCE(cr.CloseReasonNames, 'No Close Reasons') AS CloseReasonNames
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        CloseReasons cr ON cr.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
    WHERE 
        u.Reputation > 100 
),
FinalResults AS (
    SELECT 
        u.DisplayName,
        u.TotalPosts,
        u.TotalScore,
        u.AverageViewCount,
        b.BadgeCount
    FROM 
        UserPostStats u
    JOIN 
        HighReputationUsers b ON u.UserId = b.UserId
)

SELECT 
    DisplayName,
    TotalPosts,
    TotalScore,
    AverageViewCount,
    BadgeCount
FROM 
    FinalResults
ORDER BY 
    TotalScore DESC, 
    TotalPosts DESC
LIMIT 50;
