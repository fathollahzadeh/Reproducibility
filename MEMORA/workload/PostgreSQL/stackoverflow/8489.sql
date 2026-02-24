WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
UserBadges AS (
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
TopUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id, u.DisplayName, ub.BadgeCount
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.BadgeCount,
    t.QuestionCount,
    t.AnswerCount,
    t.TotalViews,
    t.TotalScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate
FROM 
    TopUserStats t
LEFT JOIN 
    RankedPosts rp ON t.UserId = rp.OwnerUserId AND rp.RN = 1
ORDER BY 
    t.TotalViews DESC, t.UserId;