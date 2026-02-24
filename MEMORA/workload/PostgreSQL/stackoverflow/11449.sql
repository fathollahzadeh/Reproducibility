
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostInteractionStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title
) 
SELECT 
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.Questions,
    UPS.Answers,
    UPS.UpvotedPosts,
    PIS.PostId,
    PIS.Title,
    PIS.CommentCount,
    PIS.UpVotes,
    PIS.DownVotes
FROM 
    UserPostStats UPS
JOIN 
    PostInteractionStats PIS ON UPS.UserId = PIS.PostId
WHERE 
    UPS.TotalPosts > 0
ORDER BY 
    UPS.TotalPosts DESC, PIS.UpVotes DESC
FETCH FIRST 50 ROWS ONLY;
