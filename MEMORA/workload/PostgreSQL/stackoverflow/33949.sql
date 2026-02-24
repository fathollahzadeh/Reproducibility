WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS TotalCloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.UserId
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalViews,
        ua.TotalScore,
        ua.QuestionCount,
        cr.TotalCloseVotes,
        RANK() OVER (ORDER BY ua.TotalScore DESC, ua.TotalViews DESC) AS UserRank
    FROM 
        UserActivity ua
    LEFT JOIN 
        CloseReasons cr ON ua.UserId = cr.UserId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.TotalViews,
    ru.TotalScore,
    ru.QuestionCount,
    COALESCE(ru.TotalCloseVotes, 0) AS TotalCloseVotes,
    ru.UserRank,
    rcte.PostId,
    rcte.Title,
    rcte.CreationDate,
    rcte.Score
FROM 
    RankedUsers ru
LEFT JOIN 
    RecursiveCTE rcte ON ru.UserId = rcte.OwnerUserId
WHERE 
    ru.QuestionCount > 0
ORDER BY 
    ru.UserRank, rcte.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;