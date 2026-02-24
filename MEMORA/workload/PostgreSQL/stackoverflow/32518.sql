
WITH RecentPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        DENSE_RANK() OVER (ORDER BY P.ViewCount DESC) AS RankByViews
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.AnswerCount, P.CommentCount, U.Reputation
),
TopPosts AS (
    SELECT 
        RPS.PostId,
        RPS.Title,
        RPS.ViewCount,
        RPS.AnswerCount,
        RPS.CommentCount,
        RPS.OwnerReputation,
        RPS.DownVotes,
        RPS.UpVotes,
        AVG(RPS.OwnerReputation) OVER () AS AvgOwnerReputation
    FROM 
        RecentPostStats RPS
    WHERE 
        RPS.RankByViews <= 10  
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
FinalResult AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.ViewCount,
        TP.AnswerCount,
        TP.CommentCount,
        TP.OwnerReputation,
        COALESCE(PC.TotalComments, 0) AS TotalComments,
        TP.DownVotes,
        TP.UpVotes,
        TP.OwnerReputation - TP.AvgOwnerReputation AS ReputationDifference
    FROM 
        TopPosts TP
    LEFT OUTER JOIN 
        PostComments PC ON TP.PostId = PC.PostId
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.ViewCount,
    FR.AnswerCount,
    FR.CommentCount,
    FR.OwnerReputation,
    FR.TotalComments,
    FR.DownVotes,
    FR.UpVotes,
    CASE 
        WHEN FR.ReputationDifference > 0 THEN 'Above Average'
        WHEN FR.ReputationDifference < 0 THEN 'Below Average'
        ELSE 'Average'
    END AS ReputationStatus
FROM 
    FinalResult FR
ORDER BY 
    FR.ViewCount DESC;
