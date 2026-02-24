
WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
PostWithBestAnswer AS (
    SELECT
        Q.PostId,
        Q.Title,
        Q.CreationDate,
        Q.Score,
        Q.ViewCount,
        A.Id AS AcceptedAnswerId,
        A.Score AS AcceptedAnswerScore
    FROM RankedPosts Q
    LEFT JOIN Posts A ON Q.PostId = A.ParentId AND A.PostTypeId = 2
    WHERE Q.Rank = 1
),
PostsForAnalysis AS (
    SELECT
        PWB.PostId,
        PWB.Title,
        PWB.CreationDate,
        PWB.Score,
        COALESCE(PWB.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(PWB.AcceptedAnswerScore, 0) AS AcceptedAnswerScore,
        COALESCE(UP.UPVoteCount, 0) AS TotalUpVotes,
        COALESCE(DW.DownVoteCount, 0) AS TotalDownVotes
    FROM PostWithBestAnswer PWB
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS UPVoteCount
        FROM Votes
        WHERE VoteTypeId = 2
        GROUP BY PostId
    ) UP ON PWB.PostId = UP.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS DownVoteCount
        FROM Votes
        WHERE VoteTypeId = 3
        GROUP BY PostId
    ) DW ON PWB.PostId = DW.PostId
),
FinalPostAnalysis AS (
    SELECT
        PFA.*,
        ROW_NUMBER() OVER (ORDER BY PFA.Score DESC) AS OverallRank,
        (SELECT AVG(Score) FROM Posts) AS AvgPostScore,
        CASE
            WHEN PFA.Score > (SELECT AVG(Score) FROM Posts) THEN 'Above Average'
            WHEN PFA.Score < (SELECT AVG(Score) FROM Posts) THEN 'Below Average'
            ELSE 'Average'
        END AS ScoreCategory
    FROM PostsForAnalysis PFA
)
SELECT *
FROM FinalPostAnalysis
WHERE AcceptedAnswerId IS NOT NULL
ORDER BY OverallRank
LIMIT 10;
