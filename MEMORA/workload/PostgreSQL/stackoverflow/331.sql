WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS AverageScore,
        COUNT(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 END) AS ClosedPostCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
VoteDetails AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes V
    GROUP BY V.UserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(VD.VoteCount, 0) AS VoteCount,
        COALESCE(VD.Upvotes, 0) AS Upvotes,
        COALESCE(VD.Downvotes, 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalPosts, 0) DESC, COALESCE(BC.BadgeCount, 0) DESC) AS Rank
    FROM Users U
    LEFT JOIN UserBadgeCounts BC ON U.Id = BC.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN VoteDetails VD ON U.Id = VD.UserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    TotalViews,
    ClosedPostCount,
    VoteCount,
    Upvotes,
    Downvotes,
    Rank
FROM CombinedStats
WHERE Rank <= 10
ORDER BY Rank;
