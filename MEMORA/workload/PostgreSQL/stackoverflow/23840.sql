WITH RankedBadges AS (
    SELECT 
        B.UserId, 
        B.Name, 
        B.Class,
        RANK() OVER (PARTITION BY B.UserId ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Badges B
    WHERE 
        B.Class = 1 
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation IS NULL THEN 0
            ELSE U.Reputation
        END AS AdjustedReputation
    FROM 
        Users U
),
QuestionStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(DISTINCT P.Id) AS QuestionCount, 
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.OwnerUserId
),
ClosedQuestions AS (
    SELECT 
        PH.UserId, 
        COUNT(DISTINCT PH.PostId) AS ClosedCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.UserId
)
SELECT 
    U.DisplayName,
    U.Location,
    U.CreationDate,
    COALESCE(RB.Name, 'No Gold Badge') AS GoldBadge,
    COALESCE(QS.QuestionCount, 0) AS QuestionsAsked,
    COALESCE(QS.TotalViews, 0) AS TotalViews,
    COALESCE(QS.AvgScore, 0) AS AvgScore,
    COALESCE(CQ.ClosedCount, 0) AS ClosedQuestions,
    UR.AdjustedReputation,
    CASE 
        WHEN UR.AdjustedReputation > 1000 THEN 'Elite'
        WHEN UR.AdjustedReputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS ReputationCategory
FROM 
    Users U
LEFT JOIN 
    RankedBadges RB ON U.Id = RB.UserId AND RB.BadgeRank = 1 
LEFT JOIN 
    QuestionStats QS ON U.Id = QS.OwnerUserId
LEFT JOIN 
    ClosedQuestions CQ ON U.Id = CQ.UserId
JOIN 
    UserReputation UR ON U.Id = UR.UserId
WHERE 
    UR.AdjustedReputation IS NOT NULL 
ORDER BY 
    UR.AdjustedReputation DESC, U.DisplayName
LIMIT 50;