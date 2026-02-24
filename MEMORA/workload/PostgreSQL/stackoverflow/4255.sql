
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalVotes,
    U.Upvotes,
    U.Downvotes,
    (U.Upvotes - U.Downvotes) AS NetVotes,
    CASE 
        WHEN U.AvgScore IS NOT NULL THEN U.AvgScore 
        ELSE 0 
    END AS AverageScore,
    P.Title AS HighScorePost,
    P.Score AS HighScore
FROM 
    UserVoteStats U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
WHERE 
    P.Score = (SELECT MAX(Score) FROM Posts WHERE OwnerUserId = U.UserId AND Score IS NOT NULL)
    AND U.TotalVotes > 0
ORDER BY 
    NetVotes DESC, 
    U.DisplayName ASC;
