WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpVotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownVotedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
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
UserPerformance AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.PostCount,
        US.QuestionCount,
        US.AnswerCount,
        US.UpVotedPosts,
        US.DownVotedPosts,
        COALESCE(BC.TotalBadges, 0) AS TotalBadges,
        COALESCE(BC.GoldBadges, 0) AS GoldBadges,
        COALESCE(BC.SilverBadges, 0) AS SilverBadges,
        COALESCE(BC.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserStats US
    LEFT JOIN 
        BadgeCounts BC ON US.UserId = BC.UserId
),
RankedPerformers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserPerformance
)
SELECT 
    RP.Rank,
    RP.DisplayName,
    RP.Reputation,
    RP.PostCount,
    RP.QuestionCount,
    RP.AnswerCount,
    RP.UpVotedPosts,
    RP.DownVotedPosts,
    RP.TotalBadges,
    RP.GoldBadges,
    RP.SilverBadges,
    RP.BronzeBadges
FROM 
    RankedPerformers RP
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Rank;
