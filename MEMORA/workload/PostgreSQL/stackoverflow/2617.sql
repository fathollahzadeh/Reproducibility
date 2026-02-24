WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(CASE 
            WHEN P.Score IS NOT NULL THEN P.Score 
            ELSE 0 
        END) AS AveragePostScore
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        MAX(P.Score) AS MaxScore
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Posts A ON P.Id = A.ParentId 
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.CreationDate
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.TotalVotes,
        U.UpVotes,
        U.DownVotes,
        P.PostId,
        P.Title,
        P.CreationDate,
        P.TotalBounty,
        P.CommentCount,
        P.AnswerCount,
        P.MaxScore,
        ROW_NUMBER() OVER (PARTITION BY U.UserId ORDER BY P.MaxScore DESC) AS Rank
    FROM UserVoteStats U
    JOIN PostDetails P ON U.UserId = P.PostId
)
SELECT 
    CS.DisplayName,
    CS.TotalVotes,
    CS.UpVotes,
    CS.DownVotes,
    CS.Title,
    CS.CreationDate,
    CS.TotalBounty,
    CS.CommentCount,
    CS.AnswerCount,
    CS.MaxScore,
    CASE 
        WHEN CS.Rank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostRank
FROM CombinedStats CS
WHERE CS.AnswerCount > 0
ORDER BY CS.MaxScore DESC, CS.DisplayName ASC;