WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id AND P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        AvgScore,
        DENSE_RANK() OVER (ORDER BY UpVotes DESC) AS RankByUpVotes,
        DENSE_RANK() OVER (ORDER BY DownVotes DESC) AS RankByDownVotes
    FROM 
        UserVoteSummary
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.UpVotes,
    A.DownVotes,
    A.PostCount,
    A.AvgScore,
    B.RankByUpVotes,
    B.RankByDownVotes
FROM 
    UserVoteSummary A
JOIN 
    TopUsers B ON A.UserId = B.UserId
WHERE 
    (A.UpVotes > (SELECT AVG(UpVotes) FROM UserVoteSummary) OR 
    A.DownVotes < (SELECT AVG(DownVotes) / 2 FROM UserVoteSummary))
ORDER BY 
    A.UpVotes DESC, A.DownVotes ASC
FETCH FIRST 10 ROWS ONLY;
