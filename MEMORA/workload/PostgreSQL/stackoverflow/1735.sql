WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        COUNT(*) AS TotalPosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS ClosedPostCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
)
SELECT 
    U.DisplayName,
    COALESCE(UVS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UVS.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PS.Questions, 0) AS TotalQuestions,
    COALESCE(PS.Answers, 0) AS TotalAnswers,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(CP.ClosedPostCount, 0) AS TotalClosedPosts
FROM 
    Users U
LEFT JOIN 
    UserVoteStats UVS ON U.Id = UVS.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON U.Id = CP.UserId
WHERE 
    (UPPER(U.DisplayName) LIKE '%ADMIN%' OR U.Reputation > 5000)
    AND (UVS.UpVotes IS NOT NULL OR UVS.DownVotes IS NOT NULL)
ORDER BY 
    TotalUpVotes DESC, TotalClosedPosts ASC
LIMIT 100 OFFSET 10;
