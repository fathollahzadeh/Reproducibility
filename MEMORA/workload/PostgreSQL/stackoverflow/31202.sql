
WITH RECURSIVE UserVotes AS (
    
    SELECT 
        U.Id AS UserId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore,
        1 AS Level
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
    
    UNION ALL
    
    SELECT 
        U.Id, 
        UV.VoteScore + SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END),
        Level + 1
    FROM 
        Users U
    JOIN 
        UserVotes UV ON UV.UserId = U.Id
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        Level < 3  
    GROUP BY 
        U.Id, UV.VoteScore, Level
),
PostDetails AS (
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty 
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
TopPosts AS (
    
    SELECT 
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.ViewCount,
        PD.CommentCount,
        PD.TotalBounty,
        UV.VoteScore AS UserVoteScore
    FROM 
        PostDetails PD
    INNER JOIN 
        UserVotes UV ON UV.UserId = (SELECT U.Id FROM Users U ORDER BY U.Reputation DESC LIMIT 1)  
    WHERE 
        PD.ViewCount > 1000 
    ORDER BY 
        PD.Score DESC
    LIMIT 5
)
SELECT 
    T.Title,
    T.Score,
    T.ViewCount,
    T.CommentCount,
    T.TotalBounty,
    CASE 
        WHEN T.UserVoteScore > 0 THEN 'Positive Feedback' 
        WHEN T.UserVoteScore < 0 THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS VoteFeedback
FROM 
    TopPosts T
LEFT JOIN 
    PostHistory PH ON T.PostId = PH.PostId
WHERE 
    PH.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = T.PostId)  
ORDER BY 
    T.UserVoteScore DESC;
