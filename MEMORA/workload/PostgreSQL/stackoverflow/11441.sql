WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RankedUsers AS (
    SELECT 
        upc.UserId,
        upc.DisplayName,
        upc.PostCount,
        upc.QuestionCount,
        upc.AnswerCount,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        RANK() OVER (ORDER BY upc.PostCount DESC) AS UserRank
    FROM 
        UserPostCounts upc
    LEFT JOIN 
        BadgeCounts bc ON upc.UserId = bc.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    BadgeCount,
    UserRank
FROM 
    RankedUsers
ORDER BY 
    UserRank
LIMIT 100;