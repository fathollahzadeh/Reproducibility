
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(rp.PostId) AS TotalQuestions,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        AVG(rp.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        u.DisplayName,
        ups.TotalQuestions,
        ups.TotalScore,
        ups.AverageScore,
        COALESCE(ub.TotalBadges, 0) AS GoldBadges,
        COALESCE(pc.EditCount, 0) AS PostEditCount
    FROM 
        UserPostStats ups
    JOIN 
        Users u ON ups.UserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostHistoryCounts pc ON pc.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id) 
)
SELECT 
    DisplayName,
    TotalQuestions,
    TotalScore,
    AverageScore,
    GoldBadges,
    PostEditCount
FROM 
    FinalResults
WHERE 
    TotalQuestions > 5 
    AND AverageScore > 5
ORDER BY 
    TotalScore DESC, 
    GoldBadges DESC;
