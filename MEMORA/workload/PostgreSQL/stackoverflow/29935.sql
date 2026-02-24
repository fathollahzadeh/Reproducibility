WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AvgScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionsCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswersCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.CommentCount, 0) AS CommentCount,
        COALESCE(PS.QuestionsCount, 0) AS QuestionsCount,
        COALESCE(PS.AnswersCount, 0) AS AnswersCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    DisplayName,
    BadgeCount,
    BadgeNames,
    PostCount,
    TotalScore,
    AvgScore,
    CommentCount,
    QuestionsCount,
    AnswersCount
FROM 
    CombinedStats
WHERE 
    PostCount > 10
ORDER BY 
    TotalScore DESC, 
    PostCount DESC;
