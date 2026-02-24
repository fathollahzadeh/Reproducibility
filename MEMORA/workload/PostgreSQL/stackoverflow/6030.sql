
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
), BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.CreationDate,
        US.TotalPosts,
        US.TotalQuestions,
        US.TotalAnswers,
        US.TotalUpVotes,
        US.TotalDownVotes,
        COALESCE(BS.TotalBadges, 0) AS TotalBadges,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserStats US
    LEFT JOIN 
        BadgeStats BS ON US.UserId = BS.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    CreationDate,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    CombinedStats
WHERE 
    Reputation > 1000
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC
FETCH FIRST 10 ROWS ONLY;
