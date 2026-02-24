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
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 12) 
        AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UsersWithCounts AS (
    SELECT 
        upc.UserId,
        upc.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadge, 0) AS GoldBadge,
        COALESCE(ub.SilverBadge, 0) AS SilverBadge,
        upc.PostCount,
        upc.QuestionCount,
        upc.AnswerCount,
        MAX(rph.CreationDate) AS LastPostAction
    FROM 
        UserPostCounts upc
    LEFT JOIN 
        UserBadges ub ON upc.UserId = ub.UserId
    LEFT JOIN 
        RecentPostHistory rph ON upc.UserId = rph.UserId
    GROUP BY 
        upc.UserId, upc.DisplayName, ub.BadgeCount, ub.GoldBadge, ub.SilverBadge, 
        upc.PostCount, upc.QuestionCount, upc.AnswerCount
)
SELECT 
    uc.UserId,
    uc.DisplayName,
    uc.PostCount,
    uc.QuestionCount,
    uc.AnswerCount,
    uc.BadgeCount,
    CASE WHEN uc.GoldBadge = 1 THEN 'Yes' ELSE 'No' END AS HasGoldBadge,
    CASE WHEN uc.SilverBadge = 1 THEN 'Yes' ELSE 'No' END AS HasSilverBadge,
    uc.LastPostAction,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    UsersWithCounts uc
LEFT JOIN 
    Comments c ON uc.UserId = c.UserId
GROUP BY 
    uc.UserId, uc.DisplayName, uc.PostCount, uc.QuestionCount, uc.AnswerCount, 
    uc.BadgeCount, uc.GoldBadge, uc.SilverBadge, uc.LastPostAction
ORDER BY 
    uc.PostCount DESC, 
    uc.QuestionCount DESC, 
    uc.AnswerCount DESC;