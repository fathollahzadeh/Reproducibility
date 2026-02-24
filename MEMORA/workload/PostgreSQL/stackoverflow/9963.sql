WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount 
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, 
        u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        ub.BadgeCount, 
        ps.PostCount, 
        ps.QuestionsCount, 
        ps.AnswersCount, 
        ps.CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ups.UserId, 
    ups.DisplayName,
    COALESCE(ups.BadgeCount, 0) AS BadgeCount, 
    COALESCE(ups.PostCount, 0) AS PostCount, 
    COALESCE(ups.QuestionsCount, 0) AS QuestionsCount, 
    COALESCE(ups.AnswersCount, 0) AS AnswersCount, 
    COALESCE(ups.CommentsCount, 0) AS CommentsCount
FROM 
    UserPostStats ups
ORDER BY 
    ups.BadgeCount DESC, 
    ups.PostCount DESC, 
    ups.QuestionsCount DESC
LIMIT 100;