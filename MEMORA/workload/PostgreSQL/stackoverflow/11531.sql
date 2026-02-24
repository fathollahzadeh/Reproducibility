WITH post_stats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.AnswerCount) AS AvgAnswerCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
user_stats AS (
    SELECT 
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Reputation
),
comment_stats AS (
    SELECT 
        COUNT(C.Id) AS TotalComments,
        AVG(LENGTH(C.Text)) AS AvgCommentLength
    FROM 
        Comments C
),
vote_stats AS (
    SELECT 
        VT.Name AS VoteType,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        VT.Name
)

SELECT 
    PS.PostType,
    PS.PostCount,
    PS.TotalScore,
    PS.AvgViewCount,
    PS.AvgAnswerCount,
    US.Reputation,
    US.BadgeCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    CS.TotalComments,
    CS.AvgCommentLength,
    VS.VoteType,
    VS.VoteCount
FROM 
    post_stats PS
CROSS JOIN 
    (SELECT DISTINCT Reputation, BadgeCount, TotalUpVotes, TotalDownVotes 
     FROM user_stats) US
CROSS JOIN 
    (SELECT TotalComments, AvgCommentLength 
     FROM comment_stats) CS
CROSS JOIN 
    (SELECT VoteType, VoteCount 
     FROM vote_stats) VS
ORDER BY 
    PS.PostType;