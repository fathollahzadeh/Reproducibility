WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
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
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),

PostHistoryTypeCounts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        SUM(CASE WHEN PHT.Name = 'Edit Body' THEN 1 ELSE 0 END) AS BodyEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Title' THEN 1 ELSE 0 END) AS TitleEdits
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UB.BadgeCount,
    UB.HighestBadgeClass,
    PS.TotalPosts,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.AverageScore,
    PHTC.EditCount,
    PHTC.BodyEdits,
    PHTC.TitleEdits
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    PostHistoryTypeCounts PHTC ON U.Id = PHTC.UserId
WHERE 
    UB.BadgeCount > 0 
    OR PS.TotalPosts > 0
ORDER BY 
    UB.BadgeCount DESC, 
    PS.TotalPosts DESC;
