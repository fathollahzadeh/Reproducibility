
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS ClosedPostCount,
        MAX(p.ClosedDate) AS LastClosedPostDate
    FROM 
        Posts p
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
BadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RankedUsers AS (
    SELECT 
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.QuestionCount,
        ups.AnswerCount,
        COALESCE(cps.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(cps.LastClosedPostDate, DATE '1970-01-01') AS LastClosedPostDate,
        bst.BadgeCount,
        bst.BadgeNames,
        ROW_NUMBER() OVER (ORDER BY ups.TotalScore DESC, ups.PostCount DESC) AS UserRank
    FROM 
        UserPostStats ups
    LEFT JOIN 
        ClosedPostStats cps ON ups.UserId = cps.OwnerUserId
    LEFT JOIN 
        BadgeStats bst ON ups.UserId = bst.UserId
)
SELECT 
    r.DisplayName,
    r.PostCount,
    r.TotalScore,
    r.QuestionCount,
    r.AnswerCount,
    r.ClosedPostCount,
    r.LastClosedPostDate,
    r.BadgeCount,
    r.BadgeNames,
    CASE 
        WHEN r.ClosedPostCount > 0 THEN CONCAT('User closed ', r.ClosedPostCount, ' posts. Last closed on ', r.LastClosedPostDate)
        ELSE 'No closed posts'
    END AS ClosureMessage,
    CASE 
        WHEN r.BadgeCount = 0 THEN 'No badges earned.'
        ELSE r.BadgeNames
    END AS BadgeMessage
FROM 
    RankedUsers r
WHERE 
    r.UserRank <= 10
ORDER BY 
    r.TotalScore DESC, r.PostCount DESC;
