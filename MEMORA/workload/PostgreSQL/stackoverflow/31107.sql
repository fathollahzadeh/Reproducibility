
WITH RECURSIVE UserReputationHistory AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 0

    UNION ALL

    SELECT
        U.Id,
        U.Reputation + (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.Id) AS Reputation,
        U.CreationDate,
        UH.Level + 1
    FROM 
        Users U
    JOIN 
        UserReputationHistory UH ON U.Id = UH.UserId
    WHERE 
        UH.Level < 5 
),

PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),

PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PVC.UpVotes,
        PVC.DownVotes,
        PVC.TotalVotes,
        ROW_NUMBER() OVER (ORDER BY PVC.UpVotes DESC, PVC.TotalVotes DESC) AS PopularityRank
    FROM 
        Posts P
    JOIN 
        PostVoteCounts PVC ON P.Id = PVC.PostId
    WHERE 
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
)

SELECT 
    U.DisplayName,
    URH.Reputation,
    PP.Title,
    PP.UpVotes,
    PP.DownVotes,
    PP.TotalVotes
FROM 
    Users U
JOIN 
    UserReputationHistory URH ON U.Id = URH.UserId
JOIN 
    PopularPosts PP ON PP.UpVotes > 5 
WHERE 
    U.Id IN (
        SELECT DISTINCT C.UserId
        FROM Comments C
        WHERE C.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
        GROUP BY C.UserId
        HAVING COUNT(*) > 10 
    )
ORDER BY 
    URH.Reputation DESC,
    PP.TotalVotes DESC;
