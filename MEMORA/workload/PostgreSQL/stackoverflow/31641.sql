WITH RECURSIVE UserBadgeCounts AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserId AS EditorId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p 
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  
)
SELECT 
    u.DisplayName, 
    u.Reputation, 
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AnswerCount, 0) AS AnswerCount,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    cph.Title AS ClosedPostTitle,
    cph.ClosedDate,
    cph.CloseReason
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    ClosedPostHistory cph ON u.Id = cph.EditorId AND cph.rn = 1
WHERE 
    u.Reputation > 500
    AND (cph.ClosedDate IS NULL OR cph.ClosedDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
ORDER BY 
    u.Reputation DESC;