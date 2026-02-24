WITH UserParticipation AS (
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
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(po.ParticipantCount, 0) AS ParticipantCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            p.Id, COUNT(DISTINCT p.OwnerUserId) AS ParticipantCount
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 2
        GROUP BY 
            p.Id
    ) po ON p.Id = po.Id
    WHERE 
        p.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.ParticipantCount
FROM 
    UserParticipation up
LEFT JOIN 
    UserBadges ub ON up.UserId = ub.UserId
LEFT JOIN 
    PostStatistics ps ON ps.ParticipantCount > 0
ORDER BY 
    up.PostCount DESC, 
    ps.ViewCount DESC
LIMIT 50;