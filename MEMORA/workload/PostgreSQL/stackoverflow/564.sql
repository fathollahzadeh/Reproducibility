
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COALESCE(SUM(VoteId.VoteCount), 0) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS VoteId ON P.Id = VoteId.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.AnswerCount,
        P.ViewCount,
        P.CreationDate,
        P.LastActivityDate,
        T.TagName
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON T.ExcerptPostId = P.Id
    WHERE 
        P.PostTypeId = 1
    ORDER BY 
        P.ViewCount DESC
    LIMIT 5
),
PostStatistics AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.AcceptedAnswers,
    UA.TotalVotes,
    PP.PostId,
    PP.Title,
    PP.AnswerCount,
    PP.ViewCount,
    PP.CreationDate,
    PP.LastActivityDate,
    PS.CloseCount,
    PS.ReopenCount,
    PS.DeleteCount
FROM 
    UserActivity UA
LEFT JOIN 
    PostStatistics PS ON PS.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = UA.UserId)
LEFT JOIN 
    PopularPosts PP ON PP.ViewCount > 100
WHERE 
    UA.ActivityRank < 11
ORDER BY 
    UA.TotalPosts DESC, UA.TotalVotes DESC;
