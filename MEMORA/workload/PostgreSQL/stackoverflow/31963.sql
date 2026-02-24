
WITH RECURSIVE UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagUsageCount,
        AVG(P.Score) AS AvgTagScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title
),
CombinedStats AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.PostCount,
        UPS.TotalScore,
        UPS.QuestionCount,
        UPS.AnswerCount,
        UB.BadgeCount,
        UB.HighestBadgeClass,
        PWC.CommentCount,
        PWC.LastCommentDate
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        UserBadges UB ON UPS.UserId = UB.UserId
    LEFT JOIN 
        PostsWithComments PWC ON UPS.UserId = PWC.PostId
)
SELECT 
    CS.DisplayName,
    CS.PostCount,
    CS.TotalScore,
    CS.QuestionCount,
    CS.AnswerCount,
    COALESCE(CS.BadgeCount, 0) AS BadgeCount,
    COALESCE(CS.HighestBadgeClass, 0) AS HighestBadgeClass,
    COALESCE(P.TagUsageCount, 0) AS TagUsageCount,
    COALESCE(P.AvgTagScore, 0) AS AvgTagScore,
    CS.CommentCount,
    CS.LastCommentDate,
    CASE 
        WHEN CS.LastCommentDate IS NOT NULL AND CS.LastCommentDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        THEN 'Active' 
        ELSE 'Inactive' 
    END AS UserStatus
FROM 
    CombinedStats CS
LEFT JOIN 
    (SELECT TagName, TagUsageCount, AvgTagScore FROM PopularTags) P ON P.TagUsageCount > 0
WHERE 
    CS.TotalScore > 100
ORDER BY 
    CS.TotalScore DESC, CS.PostCount DESC;
