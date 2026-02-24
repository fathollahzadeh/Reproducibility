
WITH ScoreSummary AS (
    SELECT 
        OwnerUserId,
        SUM(CASE WHEN PostTypeId = 1 THEN Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN PostTypeId = 2 THEN Score ELSE 0 END) AS AnswerScore,
        COUNT(CASE WHEN PostTypeId = 1 THEN Id END) AS QuestionCount,
        COUNT(CASE WHEN PostTypeId = 2 THEN Id END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserBadgeStats AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount, 
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostCommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ss.QuestionScore, 0) AS TotalQuestionScore,
        COALESCE(ss.AnswerScore, 0) AS TotalAnswerScore,
        COALESCE(b.BadgeCount, 0) AS TotalBadges,
        COALESCE(b.GoldBadges, 0) AS TotalGoldBadges,
        COALESCE(b.SilverBadges, 0) AS TotalSilverBadges,
        COALESCE(b.BronzeBadges, 0) AS TotalBronzeBadges,
        COALESCE(pcc.CommentCount, 0) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ss.QuestionScore, 0) + COALESCE(ss.AnswerScore, 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        ScoreSummary ss ON u.Id = ss.OwnerUserId
    LEFT JOIN 
        UserBadgeStats b ON u.Id = b.UserId
    LEFT JOIN 
        PostCommentCounts pcc ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pcc.PostId LIMIT 1)
    WHERE 
        (u.Reputation > 100 OR b.BadgeCount > 0) 
        AND (u.LastAccessDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
)
SELECT 
    *,
    CASE 
        WHEN TotalQuestionScore > TotalAnswerScore THEN 'Questions Dominant'
        WHEN TotalAnswerScore > TotalQuestionScore THEN 'Answers Dominant'
        ELSE 'Balanced'
    END AS UserType,
    CASE 
        WHEN TotalComments > 5 THEN 'Active Commenter'
        ELSE 'Needs More Engagement'
    END AS CommenterEngagement,
    ROW_NUMBER() OVER (
        PARTITION BY 
            CASE 
                WHEN TotalQuestionScore > TotalAnswerScore THEN 'Questions Dominant'
                WHEN TotalAnswerScore > TotalQuestionScore THEN 'Answers Dominant'
                ELSE 'Balanced'
            END 
        ORDER BY TotalQuestionScore + TotalAnswerScore DESC
    ) AS CategoryRank
FROM 
    FinalStats
WHERE 
    TotalBadges > 0 
    OR TotalQuestionScore > 0 
    OR TotalAnswerScore > 0
ORDER BY 
    Rank;
