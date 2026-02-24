
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS Comments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.LastActivityDate,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        P.OwnerUserId -- added to the group by
    FROM 
        Posts P
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.UpVotes,
    U.DownVotes,
    U.Comments,
    P.Title,
    P.ViewCount,
    P.CreationDate,
    P.LastActivityDate,
    P.HasAcceptedAnswer
FROM 
    UserStatistics U
JOIN 
    PostActivity P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.UpVotes DESC, U.TotalPosts DESC;
