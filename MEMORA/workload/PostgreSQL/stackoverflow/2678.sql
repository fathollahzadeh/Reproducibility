
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
ModerationHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.UserDisplayName,
        PH.CreationDate,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditHistoryRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13) 
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.Views,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'High'
            WHEN U.Reputation BETWEEN 100 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
)
SELECT 
    U.DisplayName AS TopUser,
    U.ReputationCategory,
    V.TotalVotes,
    V.UpVotes,
    V.DownVotes,
    M.PostId,
    M.Title,
    M.UserDisplayName AS Moderator,
    M.CreationDate AS ModerationDate,
    M.Comment AS ModerationComment
FROM 
    UserVoteStats V
JOIN 
    TopUsers U ON V.UserId = U.Id
LEFT JOIN 
    ModerationHistory M ON M.PostId IN (SELECT DISTINCT PostId FROM Votes WHERE UserId = U.Id)
WHERE 
    V.TotalVotes > 5
ORDER BY 
    V.TotalVotes DESC, M.CreationDate DESC
LIMIT 10 OFFSET 0;
