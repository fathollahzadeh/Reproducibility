WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
QuestionStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViews,
        MAX(rp.Score) AS MaxScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
    GROUP BY 
        rp.OwnerDisplayName
),
UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalReport AS (
    SELECT 
        qs.OwnerDisplayName,
        qs.QuestionCount,
        qs.TotalScore,
        qs.AvgViews,
        qs.MaxScore,
        ub.BadgeCount
    FROM 
        QuestionStats qs
    JOIN 
        Users u ON qs.OwnerDisplayName = u.DisplayName
    JOIN 
        UserBadgeCount ub ON u.Id = ub.UserId
)
SELECT 
    OwnerDisplayName,
    QuestionCount,
    TotalScore,
    AvgViews,
    MaxScore,
    BadgeCount
FROM 
    FinalReport
ORDER BY 
    TotalScore DESC, QuestionCount DESC
LIMIT 50;