
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(VoteCount.VoteTotal, 0)) AS TotalVotes,
        SUM(COALESCE(P.AcceptedAnswerId, 0, 0) + P.Score) AS ScoreTotal,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users AS U
        LEFT JOIN Posts AS P ON U.Id = P.OwnerUserId
        LEFT JOIN Comments AS C ON P.Id = C.PostId
        LEFT JOIN (
            SELECT 
                PostId, 
                COUNT(Id) AS VoteTotal 
            FROM 
                Votes 
            GROUP BY 
                PostId
        ) AS VoteCount ON P.Id = VoteCount.PostId
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.Reputation,
        UA.DisplayName,
        UA.PostCount,
        UA.TotalVotes,
        UA.ScoreTotal,
        UA.CommentCount,
        ROW_NUMBER() OVER (ORDER BY UA.ScoreTotal DESC, UA.TotalVotes DESC) AS Rank
    FROM 
        UserActivity AS UA
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.TotalVotes,
    TU.ScoreTotal,
    TU.CommentCount
FROM 
    TopUsers AS TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank;
