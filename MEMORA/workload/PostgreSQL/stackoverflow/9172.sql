
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN P.PostTypeId = 4 THEN 1 ELSE 0 END) AS TagWikis,
        SUM(CASE WHEN P.PostTypeId = 5 THEN 1 ELSE 0 END) AS TagWikiExcerpts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
BadgeCounts AS (
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
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.Questions,
        US.Answers,
        US.Wikis,
        US.TagWikis,
        US.TagWikiExcerpts,
        BC.TotalBadges,
        BC.GoldBadges,
        BC.SilverBadges,
        BC.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY US.Reputation DESC) AS Rank
    FROM 
        UserStatistics US
    LEFT JOIN 
        BadgeCounts BC ON US.UserId = BC.UserId
)
SELECT 
    Rank,
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    Questions,
    Answers,
    Wikis,
    TagWikis,
    TagWikiExcerpts,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
