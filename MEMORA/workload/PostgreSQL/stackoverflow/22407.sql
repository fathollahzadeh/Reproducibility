WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN p.Score > 0 THEN p.Score END, 0)) AS PositiveScoreSum,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
EngagementSummary AS (
    SELECT 
        u.Id AS UserId,
        ub.DisplayName,
        ub.BadgeCount,
        pa.QuestionCount,
        pa.AnswerCount,
        pa.TotalPosts,
        pa.TotalViews,
        pa.PositiveScoreSum,
        CASE 
            WHEN pa.QuestionCount > pa.AnswerCount THEN 'More Questions'
            WHEN pa.QuestionCount < pa.AnswerCount THEN 'More Answers'
            ELSE 'Equal Questions and Answers'
        END AS PostTypeDominance
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostActivity pa ON ub.UserId = pa.OwnerUserId
    INNER JOIN 
        Users u ON ub.UserId = u.Id
    WHERE 
        (ub.BadgeCount > 0 OR pa.TotalPosts > 0)
    ORDER BY 
        ub.BadgeCount DESC, 
        pa.TotalPosts DESC
)
SELECT 
    e.UserId,
    e.DisplayName,
    COALESCE(e.BadgeCount, 0) AS BadgeCount,
    COALESCE(e.QuestionCount, 0) AS QuestionCount,
    COALESCE(e.AnswerCount, 0) AS AnswerCount,
    COALESCE(e.TotalPosts, 0) AS TotalPosts,
    COALESCE(e.TotalViews, 0) AS TotalViews,
    COALESCE(e.PositiveScoreSum, 0) AS PositiveScoreSum,
    e.PostTypeDominance,
    CASE 
        WHEN e.TotalViews IS NULL OR e.TotalPosts IS NULL THEN 'Unknown Engagement'
        ELSE CASE 
            WHEN e.TotalViews > e.TotalPosts * 10 THEN 'High Engagement'
            WHEN e.TotalViews < e.TotalPosts * 2 THEN 'Low Engagement'
            ELSE 'Medium Engagement'
        END
    END AS EngagementLevel
FROM 
    EngagementSummary e
WHERE 
    (e.QuestionCount + e.AnswerCount) > 0
    AND e.TotalViews IS NOT NULL
ORDER BY 
    CASE 
        WHEN e.PostTypeDominance = 'More Questions' THEN 1
        WHEN e.PostTypeDominance = 'More Answers' THEN 2
        ELSE 3
    END,
    e.BadgeCount DESC,
    e.TotalViews DESC;
