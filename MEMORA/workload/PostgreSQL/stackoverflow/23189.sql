
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgeCount,
        COUNT(b.Id) AS TotalBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount END) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        p.OwnerUserId,
        COUNT(*) AS ClosedPostCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.UserId, p.OwnerUserId
),
FinalResults AS (
    SELECT 
        u.DisplayName,
        ubc.GoldBadgeCount,
        ubc.SilverBadgeCount,
        ubc.BronzeBadgeCount,
        p.PostCount,
        p.TotalScore,
        COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount,
        ROW_NUMBER() OVER (ORDER BY p.TotalScore DESC, p.PostCount DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN 
        PostStats p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON u.Id = cp.UserId
)
SELECT 
    *,
    CASE 
        WHEN ClosedPostCount > 5 THEN 'Frequent Closer'
        ELSE 'Occasional Closer'
    END AS ClosureFrequency,
    CONCAT(DisplayName, ' has ', TotalScore, ' points') AS UserSummary
FROM 
    FinalResults
WHERE 
    (GoldBadgeCount + SilverBadgeCount + BronzeBadgeCount) > 0
    AND TotalScore > 100
ORDER BY 
    UserRank
FETCH FIRST 10 ROWS ONLY;
