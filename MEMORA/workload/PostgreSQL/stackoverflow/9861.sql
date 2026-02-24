WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END) AS TotalQuestionViews,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.ViewCount ELSE 0 END) AS TotalAnswerViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        P.CreationDate,
        U.DisplayName AS OwnerName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
    ORDER BY 
        P.ViewCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UPS.UserId, 
    UPS.DisplayName, 
    UPS.TotalPosts, 
    UPS.QuestionsCount, 
    UPS.AnswersCount, 
    UPS.TotalQuestionViews, 
    UPS.TotalAnswerViews, 
    UB.BadgeCount,
    TQ.PostId,
    TQ.Title AS TopQuestionTitle,
    TQ.Score,
    TQ.ViewCount AS TopQuestionViews,
    TQ.CreationDate AS TopQuestionDate,
    TQ.OwnerName AS TopQuestionOwner
FROM 
    UserPostStats UPS
LEFT JOIN 
    UserBadges UB ON UPS.UserId = UB.UserId
LEFT JOIN 
    TopQuestions TQ ON UPS.QuestionsCount > 0
WHERE 
    UPS.TotalPosts > 0
ORDER BY 
    UPS.TotalPosts DESC, 
    UPS.UserId;
