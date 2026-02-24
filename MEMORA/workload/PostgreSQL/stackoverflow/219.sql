
WITH UserVotingStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT V.PostId) AS TotalVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        PH.CreationDate AS CloseDate,
        PT.Name AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes PT ON PT.Id = CAST(PH.Comment AS INT)
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.TotalVotes,
    CP.Title,
    CP.CloseDate,
    CP.CloseReason
FROM 
    UserVotingStats U
LEFT JOIN 
    ClosedPosts CP ON U.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Posts.Id = CP.Id)
WHERE 
    U.TotalVotes > 0
ORDER BY 
    U.UpVotes DESC,
    U.DownVotes ASC
LIMIT 10;
