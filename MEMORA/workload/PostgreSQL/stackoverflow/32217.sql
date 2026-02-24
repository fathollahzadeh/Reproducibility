WITH RECURSIVE UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentVotes AS (
    SELECT
        V.PostId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        V.PostId
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        COALESCE(RV.VoteCount, 0) AS RecentVoteCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, COALESCE(RV.VoteCount, 0) DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        RecentVotes RV ON P.Id = RV.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
        AND P.PostTypeId = 1  
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.PositivePosts,
    UPS.NegativePosts,
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.AnswerCount,
    TP.RecentVoteCount
FROM 
    UserPostStats UPS
INNER JOIN 
    TopPosts TP ON UPS.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
WHERE 
    UPS.TotalPosts > 10
    AND UPS.PostRank <= 100
ORDER BY 
    UPS.PositivePosts DESC,
    TP.Score DESC
LIMIT 50;