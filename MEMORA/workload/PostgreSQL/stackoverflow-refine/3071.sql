
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentEdits AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalSummary AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.Questions,
        ua.Answers,
        ua.TotalViews,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        COALESCE(re.EditCount, 0) AS EditCount,
        COALESCE(re.LastEditDate, '1970-01-01 00:00:00') AS LastEditDate,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        UserActivity ua
    LEFT JOIN 
        RecentEdits re ON ua.UserId = re.UserId
    LEFT JOIN 
        UserBadges ub ON ua.UserId = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalUpvotes,
    TotalDownvotes,
    EditCount,
    LastEditDate,
    BadgeCount,
    CASE 
        WHEN TotalPosts > 100 THEN 'Active Contributor'
        WHEN TotalPosts BETWEEN 50 AND 100 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM 
    FinalSummary
WHERE 
    TotalPosts > 0
ORDER BY 
    TotalViews DESC, TotalPosts DESC
FETCH FIRST 10 ROWS ONLY;
