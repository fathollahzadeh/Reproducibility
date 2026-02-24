
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), PostHistoryCounts AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS TotalPostHistory
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        PH.UserId
), UserRankings AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.TotalPosts,
        U.QuestionsCount,
        U.AnswersCount,
        U.TotalScore,
        U.AvgViewCount,
        COALESCE(BC.TotalBadges, 0) AS TotalBadges,
        COALESCE(PH.TotalPostHistory, 0) AS TotalPostHistory,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        UserStatistics U
    LEFT JOIN 
        BadgeCounts BC ON U.UserId = BC.UserId
    LEFT JOIN 
        PostHistoryCounts PH ON U.UserId = PH.UserId
)
SELECT 
    RR.UserId,
    RR.DisplayName,
    RR.Reputation,
    RR.TotalPosts,
    RR.QuestionsCount,
    RR.AnswersCount,
    RR.TotalScore,
    ROUND(RR.AvgViewCount, 2) AS AvgViewCount,
    RR.TotalBadges,
    RR.TotalPostHistory,
    RR.Rank,
    CASE 
        WHEN RR.TotalPosts = 0 THEN 'No Posts'
        WHEN RR.AnswersCount > RR.QuestionsCount THEN 'More Answers'
        ELSE 'More Questions'
    END AS PostTypeFeedback
FROM 
    UserRankings RR
ORDER BY 
    RR.Rank
LIMIT 10;
