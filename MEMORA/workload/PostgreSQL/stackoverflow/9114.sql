
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        CommentCount,
        PostCount,
        (UpVotes - DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY PostCount DESC, (UpVotes - DownVotes) DESC) AS UserRank
    FROM 
        UserEngagement
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.UpVotes,
    TU.DownVotes,
    TU.CommentCount,
    TU.PostCount,
    TU.NetVotes
FROM 
    TopUsers TU
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UserRank;
