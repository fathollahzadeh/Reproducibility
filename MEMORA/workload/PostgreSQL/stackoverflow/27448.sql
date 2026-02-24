WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
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
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
EnhancedUserStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ub.BadgeNames,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.TotalScore,
        ps.AvgViewCount
    FROM 
        UserBadges ub
    JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    eus.DisplayName,
    eus.BadgeCount,
    eus.BadgeNames,
    eus.PostCount,
    eus.QuestionCount,
    eus.AnswerCount,
    eus.TotalScore,
    eus.AvgViewCount
FROM 
    EnhancedUserStats eus
ORDER BY 
    eus.TotalScore DESC, 
    eus.BadgeCount DESC;