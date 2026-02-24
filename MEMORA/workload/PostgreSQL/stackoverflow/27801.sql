
WITH TagStats AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
CloseReasons AS (
    SELECT
        ph.Comment AS CloseReason,
        COUNT(ph.Id) AS CloseReasonCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN CAST(ph.CreationDate AS DATE) = DATE '2024-10-01' THEN 1 ELSE 0 END) AS TodayCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.Comment
    ORDER BY 
        CloseReasonCount DESC
    LIMIT 5
),
UserBadgeCount AS (
    SELECT
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.DisplayName
    ORDER BY 
        BadgeCount DESC
    LIMIT 10
)
SELECT 
    t.TagName,
    t.PostCount,
    t.AnswerCount,
    t.AverageUserReputation,
    t.TopUsers,
    c.CloseReason,
    c.CloseReasonCount,
    c.TotalViews,
    c.TodayCount,
    u.DisplayName AS TopUserWithBadges,
    u.BadgeCount
FROM 
    TagStats t
LEFT JOIN 
    CloseReasons c ON true
LEFT JOIN 
    UserBadgeCount u ON true
ORDER BY 
    t.PostCount DESC, 
    u.BadgeCount DESC;
