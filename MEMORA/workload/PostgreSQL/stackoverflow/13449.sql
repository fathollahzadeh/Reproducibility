WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
        LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.Id, T.TagName
),
BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    U.UserId,
    U.DisplayName,
    COALESCE(U.PostCount, 0) AS TotalPosts,
    COALESCE(U.Questions, 0) AS TotalQuestions,
    COALESCE(U.Answers, 0) AS TotalAnswers,
    COALESCE(U.TotalViews, 0) AS TotalViews,
    COALESCE(U.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(U.TotalDownVotes, 0) AS TotalDownVotes,
    COALESCE(B.BadgeCount, 0) AS TotalBadges,
    COALESCE(B.GoldBadges, 0) AS TotalGoldBadges,
    COALESCE(B.SilverBadges, 0) AS TotalSilverBadges,
    COALESCE(B.BronzeBadges, 0) AS TotalBronzeBadges
FROM 
    UserStats U
    LEFT JOIN BadgeStats B ON U.UserId = B.UserId
ORDER BY 
    U.TotalViews DESC, U.PostCount DESC;