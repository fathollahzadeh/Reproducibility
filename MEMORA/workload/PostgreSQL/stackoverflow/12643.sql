
WITH PostStats AS (
    SELECT 
        P.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViewCount,
        AVG(Score) AS AverageScore,
        AVG(AnswerCount) AS AverageAnswerCount,
        AVG(CommentCount) AS AverageCommentCount
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        AVG(U.Reputation) AS AverageReputation
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    PST.PostTypeId,
    PST.TotalPosts,
    PST.AverageViewCount,
    PST.AverageScore,
    PST.AverageAnswerCount,
    PST.AverageCommentCount,
    US.TotalBadges,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.AverageReputation
FROM PostStats PST
JOIN UserStats US ON US.UserId = (SELECT MIN(Id) FROM Users)  
ORDER BY PST.PostTypeId;
