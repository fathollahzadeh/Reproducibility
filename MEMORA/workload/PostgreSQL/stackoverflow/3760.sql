WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId IN (3) THEN 1 ELSE 0 END) AS Downvotes,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(PV.VoteCount, 0) AS TotalVotes,
        COALESCE(C.CommentCount, 0) AS TotalComments,
        COALESCE(A.AcceptedAnswerCount, 0) AS AcceptedAnswers
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) PV ON P.Id = PV.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            ParentId, COUNT(*) AS AcceptedAnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 AND AcceptedAnswerId IS NOT NULL
        GROUP BY 
            ParentId
    ) A ON P.Id = A.ParentId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
)
SELECT 
    U.DisplayName,
    S.AvgPostScore,
    PS.Title,
    PS.TotalVotes,
    PS.TotalComments,
    PS.AcceptedAnswers
FROM 
    UserVoteSummary U
JOIN 
    PostStatistics PS ON U.UserId = PS.PostId
JOIN 
    (SELECT UserId, AVG(Score) AS AvgPostScore
     FROM Posts 
     WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '2 years'
     GROUP BY UserId) S ON U.UserId = S.UserId
WHERE 
    PS.TotalVotes > 5
ORDER BY 
    S.AvgPostScore DESC, PS.TotalVotes DESC
LIMIT 10;