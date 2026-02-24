
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (5, 6) THEN 1 ELSE 0 END) AS TotalWikiPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PopularTags AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS UsageCount
    FROM
        Tags T
    JOIN
        Posts P ON POSITION('>' || T.TagName || '<' IN P.Tags) > 0
    GROUP BY
        T.TagName
    HAVING
        COUNT(P.Id) > 50
),
ClosedPostReasons AS (
    SELECT
        PH.UserId,
        PH.Comment,
        COUNT(*) AS CloseReasonCount
    FROM
        PostHistory PH
    WHERE
        PH.PostHistoryTypeId = 10 
    GROUP BY
        PH.UserId, PH.Comment
),
FinalBenchmark AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.TotalWikiPosts,
        US.TotalUpvotes,
        US.TotalDownvotes,
        US.GoldBadges,
        US.SilverBadges,
        US.BronzeBadges,
        PT.TagName,
        PT.UsageCount,
        CPR.CloseReasonCount
    FROM
        UserStats US
    JOIN
        PopularTags PT ON US.TotalPosts > (SELECT AVG(TotalPosts) FROM UserStats)
    LEFT JOIN
        ClosedPostReasons CPR ON US.UserId = CPR.UserId
    WHERE
        US.Reputation > 1000
    ORDER BY
        US.Reputation DESC, US.TotalPosts DESC
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalWikiPosts,
    TotalUpvotes,
    TotalDownvotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TagName,
    UsageCount,
    CloseReasonCount
FROM
    FinalBenchmark
FETCH FIRST 100 ROWS ONLY;
