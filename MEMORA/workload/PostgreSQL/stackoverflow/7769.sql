WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePostsCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePostsCount,
        SUM(COALESCE(UPVOTES.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(DOWNVOTES.DownVoteCount, 0)) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS UpVoteCount 
        FROM Votes V 
        WHERE V.VoteTypeId = 2 
        GROUP BY PostId
    ) UPVOTES ON P.Id = UPVOTES.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS DownVoteCount 
        FROM Votes V 
        WHERE V.VoteTypeId = 3 
        GROUP BY PostId
    ) DOWNVOTES ON P.Id = DOWNVOTES.PostId
    GROUP BY U.Id, U.DisplayName
)

SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.QuestionsCount,
    UA.AnswersCount,
    UA.PositivePostsCount,
    UA.NegativePostsCount,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    RANK() OVER (ORDER BY UA.TotalPosts DESC) AS UserRank
FROM 
    UserActivity UA
WHERE 
    UA.TotalPosts > 0 
ORDER BY 
    UA.TotalPosts DESC, UA.DisplayName ASC
LIMIT 10;
