WITH UserBadgeCounts AS (
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
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleAndBodyEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ubc.BadgeCount,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalViews,
    phs.EditCount,
    phs.TitleAndBodyEdits
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
LEFT JOIN 
    UserPostStats ups ON u.Id = ups.OwnerUserId
LEFT JOIN 
    PostHistoryStats phs ON u.Id = phs.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    ubc.BadgeCount DESC, 
    ups.TotalViews DESC
LIMIT 100;
