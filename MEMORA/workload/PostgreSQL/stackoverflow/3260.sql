
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostWithMaxVotes AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT V.Id) AS VoteCount,
        ROW_NUMBER() OVER(PARTITION BY P.OwnerUserId ORDER BY COUNT(DISTINCT V.Id) DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    U.DisplayName AS UserName,
    U.TotalPosts,
    U.UpVotes,
    U.DownVotes,
    P.Title AS TopPostTitle,
    PM.VoteCount,
    CP.CloseDate,
    CP.CloseReason
FROM 
    UserVoteStats U
LEFT JOIN 
    PostWithMaxVotes PM ON U.UserId = PM.PostId
LEFT JOIN 
    Posts P ON PM.PostId = P.Id
LEFT JOIN 
    ClosedPosts CP ON P.Id = CP.PostId
WHERE 
    U.TotalPosts > 0 
    AND (U.UpVotes - U.DownVotes) > 10
ORDER BY 
    U.UpVotes DESC, U.DisplayName;
