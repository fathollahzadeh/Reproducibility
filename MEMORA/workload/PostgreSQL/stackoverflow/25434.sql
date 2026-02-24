
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.ViewCount) AS AverageViewCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        T.TagName
),
HighScoringTags AS (
    SELECT 
        TagName,
        PostCount,
        AverageViewCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10 
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AverageViewCount,
        TotalScore
    FROM 
        HighScoringTags
    WHERE 
        ScoreRank <= 10 
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT C.Id) AS CommentsMade,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Comments C ON U.Id = C.UserId 
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1) 
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    T.TagName,
    T.PostCount,
    T.AverageViewCount,
    T.TotalScore,
    U.UserId,
    U.DisplayName,
    U.QuestionsAsked,
    U.CommentsMade,
    U.UpVotesReceived
FROM 
    TopTags T
JOIN 
    UserActivity U ON U.QuestionsAsked > 0 
ORDER BY 
    T.TotalScore DESC, U.UpVotesReceived DESC;
