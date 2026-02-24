WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS Score,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score AS PostScore,
        P.ViewCount,
        COALESCE(CNT.CommentsCount, 0) AS CommentsCount,
        COALESCE(AN.Count, 0) AS AnswerCount    
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentsCount FROM Comments GROUP BY PostId) CNT ON P.Id = CNT.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS Count FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) AN ON P.Id = AN.ParentId
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        UserScores
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PostScore DESC) AS Rank
    FROM 
        PostStatistics
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Score AS UserScore,
    P.PostId,
    P.Title,
    P.PostScore,
    P.ViewCount,
    P.CommentsCount,
    P.AnswerCount,
    U.Rank AS UserRank,
    P.Rank AS PostRank
FROM 
    TopUsers U
JOIN 
    TopPosts P ON U.UserId = P.PostId
WHERE 
    U.Rank <= 10 AND P.Rank <= 10
ORDER BY 
    U.Rank, P.Rank;