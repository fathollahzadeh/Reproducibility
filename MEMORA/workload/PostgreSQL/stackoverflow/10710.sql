WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
AggregatedData AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        COALESCE(up.PostCount, 0) AS PostCount,
        COALESCE(up.QuestionCount, 0) AS QuestionCount,
        COALESCE(up.AnswerCount, 0) AS AnswerCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        UserPostCounts up ON u.Id = up.UserId
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
)
SELECT 
    UserId,
    Reputation,
    CreationDate,
    PostCount,
    QuestionCount,
    AnswerCount,
    BadgeCount
FROM 
    AggregatedData
ORDER BY 
    Reputation DESC
LIMIT 100;
