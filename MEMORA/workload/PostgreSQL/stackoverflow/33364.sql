WITH RECURSIVE UserPostStats AS (
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
    GROUP BY u.Id, u.DisplayName
),

BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY UserId
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastTitleEdit,
        MAX(CASE WHEN ph.PostHistoryTypeId = 5 THEN ph.CreationDate END) AS LastBodyEdit
    FROM 
        PostHistory ph
    GROUP BY ph.PostId
),

UserPostSummary AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.EditCount, 0) AS EditCount,
        ps.LastTitleEdit,
        ps.LastBodyEdit
    FROM 
        UserPostStats ups
    LEFT JOIN 
        BadgeCounts bc ON ups.UserId = bc.UserId
    LEFT JOIN 
        PostHistoryStats ps ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)

)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.BadgeCount,
    ups.EditCount,
    DATE_TRUNC('day', COALESCE(ups.LastTitleEdit, ups.LastBodyEdit)) AS LastEditDate,
    CASE 
        WHEN (ups.QuestionCount + ups.AnswerCount) > 100 THEN 'Active Contributor' 
        WHEN ups.BadgeCount > 5 THEN 'Seasoned User' 
        ELSE 'New User' 
    END AS UserCategory
FROM 
    UserPostSummary ups
WHERE 
    ups.PostCount > 0
ORDER BY 
    ups.QuestionCount DESC,
    ups.AnswerCount DESC
LIMIT 50;
