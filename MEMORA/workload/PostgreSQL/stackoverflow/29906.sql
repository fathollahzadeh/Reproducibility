
WITH TagCount AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
    WHERE 
        PostCount > 10 
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
TagEngagement AS (
    SELECT 
        T.TagName,
        SUM(UE.QuestionCount) AS TotalQuestions,
        SUM(UE.CommentCount) AS TotalComments,
        SUM(UE.UpVoteCount) AS TotalUpVotes,
        SUM(UE.DownVoteCount) AS TotalDownVotes
    FROM 
        TopTags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    JOIN 
        UserEngagement UE ON P.OwnerUserId = UE.UserId
    GROUP BY 
        T.TagName
)
SELECT 
    TE.TagName,
    TE.TotalQuestions,
    TE.TotalComments,
    TE.TotalUpVotes,
    TE.TotalDownVotes,
    CASE 
        WHEN TE.TotalQuestions > 100 THEN 'Very Active'
        WHEN TE.TotalQuestions BETWEEN 50 AND 100 THEN 'Active'
        ELSE 'Less Active'
    END AS EngagementLevel
FROM 
    TagEngagement TE
WHERE 
    TE.TotalQuestions > 0
ORDER BY 
    TE.TotalQuestions DESC;
