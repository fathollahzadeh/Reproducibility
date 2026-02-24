
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COALESCE(SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsCount,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswersProvided,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5  
),
UserEngagement AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionsAsked,
        UA.AnswersProvided,
        UA.CommentsCount,
        UA.UpVotesReceived,
        UA.DownVotesReceived,
        UA.TotalViews,
        PT.Tag,
        PCT.PostCount
    FROM 
        UserActivity UA
    JOIN 
        Posts P ON UA.UserId = P.OwnerUserId
    JOIN 
        PopularTags PT ON PT.Tag = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))
    JOIN 
        TagCounts PCT ON PT.Tag = PCT.Tag
)
SELECT 
    UE.DisplayName,
    UE.QuestionsAsked,
    UE.AnswersProvided,
    UE.CommentsCount,
    SUM(UE.UpVotesReceived - UE.DownVotesReceived) AS NetVotes,
    SUM(UE.TotalViews) AS TotalViews,
    STRING_AGG(DISTINCT UE.Tag, ', ') AS RelatedTags,
    COUNT(DISTINCT UE.Tag) AS UniqueTagsEngaged
FROM 
    UserEngagement UE
GROUP BY 
    UE.DisplayName, UE.QuestionsAsked, UE.AnswersProvided, UE.CommentsCount
ORDER BY 
    TotalViews DESC
FETCH FIRST 10 ROWS ONLY;
