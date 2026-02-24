WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE 
            WHEN Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostActivity AS (
    SELECT 
        OwnerUserId,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionsAsked,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswersGiven,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        PostId,
        UserId,
        MAX(CreationDate) AS MostRecentEdit
    FROM 
        PostHistory
    GROUP BY 
        PostId, UserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PA.QuestionsAsked, 0) AS QuestionsAsked,
        COALESCE(PA.AnswersGiven, 0) AS AnswersGiven,
        COALESCE(PA.TotalViews, 0) AS TotalViews,
        COALESCE(PA.TotalScore, 0) AS TotalScore,
        CASE 
            WHEN U.LastAccessDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Inactive'
            ELSE 'Active'
        END AS UserStatus
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostActivity PA ON U.Id = PA.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.BadgeCount,
    TU.QuestionsAsked,
    TU.AnswersGiven,
    TU.TotalViews,
    TU.TotalScore,
    TU.UserStatus,
    ARRAY_AGG(RPH.UserId) AS RecentEditors
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPostHistory RPH ON TU.Id = RPH.UserId
GROUP BY 
    TU.DisplayName, TU.Reputation, TU.BadgeCount, TU.QuestionsAsked, TU.AnswersGiven, TU.TotalViews, TU.TotalScore, TU.UserStatus
ORDER BY 
    TU.Reputation DESC, TU.QuestionsAsked DESC
LIMIT 10;