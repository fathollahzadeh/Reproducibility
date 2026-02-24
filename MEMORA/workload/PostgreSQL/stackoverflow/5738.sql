WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(COALESCE(IP.VoteCount, 0)) AS VotesReceived,
        SUM(COALESCE(C.CommentCount, 0)) AS CommentsCount,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS IP ON IP.PostId = P.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) AS C ON C.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostsCount, 
        VotesReceived, 
        CommentsCount, 
        AverageReputation,
        DENSE_RANK() OVER (ORDER BY VotesReceived DESC) AS Rank
    FROM 
        UserEngagement
)
SELECT 
    UserId, 
    DisplayName, 
    PostsCount, 
    VotesReceived, 
    CommentsCount, 
    AverageReputation
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    VotesReceived DESC;
