
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RecentComments AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        C.UserId
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    COALESCE(UP.PostCount, 0) AS TotalPosts,
    COALESCE(UP.QuestionCount, 0) AS TotalQuestions,
    COALESCE(UP.AnswerCount, 0) AS TotalAnswers,
    COALESCE(RC.CommentCount, 0) AS RecentComments,
    UB.BadgeCount
FROM 
    UserBadges UB
LEFT JOIN 
    UserPosts UP ON UB.UserId = UP.OwnerUserId
LEFT JOIN 
    RecentComments RC ON UB.UserId = RC.UserId
ORDER BY 
    UB.BadgeCount DESC, TotalPosts DESC, UB.DisplayName;
