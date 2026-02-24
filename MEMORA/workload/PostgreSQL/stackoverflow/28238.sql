
WITH ProcessedTags AS (
    SELECT 
        P.Id AS PostId,
        UNNEST(string_to_array(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><')) AS TagName,
        P.Title,
        P.Body,
        P.CreationDate
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TagUsageCount,
        AVG(U.QuestionCount) AS AvgQuestionsPerUser,
        SUM(U.UpVoteCount) AS TotalUpVotes
    FROM 
        ProcessedTags T
    JOIN Posts P ON T.PostId = P.Id
    JOIN UserEngagement U ON P.OwnerUserId = U.UserId
    GROUP BY 
        T.TagName
),
EngagingTags AS (
    SELECT 
        TagName,
        TagUsageCount,
        AvgQuestionsPerUser,
        TotalUpVotes,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS PopularityRank
    FROM 
        TagStatistics
    WHERE 
        TagUsageCount > 10  
)
SELECT 
    TagName,
    TagUsageCount,
    AvgQuestionsPerUser,
    TotalUpVotes,
    PopularityRank
FROM 
    EngagingTags
WHERE 
    PopularityRank <= 10  
ORDER BY 
    PopularityRank;
