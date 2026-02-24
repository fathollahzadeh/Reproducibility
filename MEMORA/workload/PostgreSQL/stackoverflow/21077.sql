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
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ModeratedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionCount,
        ARRAY_AGG(ph.Comment) AS ClosureReasons
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
)
SELECT 
    ub.DisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.TotalViews,
    ps.TotalScore,
    COALESCE(mp.ClosureCount, 0) AS ClosureCount,
    COALESCE(mp.DeletionCount, 0) AS DeletionCount,
    CASE 
        WHEN COALESCE(mp.ClosureReasons, '{}') = '{}' THEN 'No closure reasons'
        ELSE 'Reasons: ' || ARRAY_TO_STRING(mp.ClosureReasons, ', ')
    END AS ClosureDetails,
    DATE_PART('year', AGE(ps.LastPostDate)) AS YearsSinceLastPost,
    ROW_NUMBER() OVER (PARTITION BY ub.UserId ORDER BY ub.BadgeCount DESC NULLS LAST) AS BadgeRank
FROM 
    UserBadges ub
LEFT JOIN 
    PostStats ps ON ub.UserId = ps.OwnerUserId
LEFT JOIN 
    ModeratedPosts mp ON ps.OwnerUserId = mp.OwnerUserId
WHERE 
    ub.BadgeCount > 0 OR ps.QuestionCount > 0
ORDER BY 
    ub.BadgeCount DESC, ps.TotalViews DESC
LIMIT 100;